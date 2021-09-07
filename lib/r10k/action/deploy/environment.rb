require 'r10k/util/setopts'
require 'r10k/util/cleaner'
require 'r10k/deployment'
require 'r10k/logging'
require 'r10k/action/visitor'
require 'r10k/action/base'
require 'r10k/action/deploy/deploy_helpers'
require 'json'

module R10K
  module Action
    module Deploy
      class Environment < R10K::Action::Base

        include R10K::Action::Deploy::DeployHelpers

        # Deprecated
        attr_reader :force

        attr_reader :settings

        # @param opts [Hash] A hash of options defined in #allowed_initialized_opts
        #   and managed by the SetOps mixin within the Action::Base class.
        #   Corresponds to the CLI flags and options.
        # @param argv [Enumerable] Typically CRI::ArgumentList or Array. A list-like
        #   collection of the remaining arguments to the CLI invocation (after
        #   removing flags and options).
        # @param settings [Hash] A hash of configuration loaded from the relevant
        #   config (r10k.yaml).
        #
        # @note All arguments will be required in the next major version
        def initialize(opts, argv, settings = {})
          super

          # instance variables below are set by the super class based on the
          # spec of #allowed_initialize_opts and any command line flags. This
          # gives a preference order of cli flags > config files > defaults.
          @settings = @settings.merge({
            overrides: {
              environments: {
                requested_environments: @argv.map { |arg| arg.gsub(/\W/,'_') },
                default_branch_override: @default_branch_override,
                generate_types: @generate_types || settings.dig(:deploy, :generate_types) || false,
                preload_environments: true,
                incremental: @incremental
              },
              modules: {
                exclude_spec: settings.dig(:deploy, :exclude_spec),
                requested_modules: [],
                deploy_modules: @modules,
                pool_size: @settings[:pool_size] || 4,
                force: !@no_force, # force here is used to make it easier to reason about
              },
              purging: {
                purge_levels: settings.dig(:deploy, :purge_levels) || [],
                purge_allowlist: read_purge_allowlist(settings.dig(:deploy, :purge_whitelist) || [],
                                                      settings.dig(:deploy, :purge_allowlist) || [])
              },
              forge: {
                allow_puppetfile_override: settings.dig(:forge, :allow_puppetfile_override) || false
              },
              output: {}
            }
          })
        end

        def call
          @visit_ok = true

          begin
            expect_config!
            deployment = R10K::Deployment.new(@settings)
            check_write_lock!(@settings)

            deployment.accept(self)
          rescue => e
            @visit_ok = false
            logger.error R10K::Errors::Formatting.format_exception(e, @trace)
          end

          @visit_ok
        end

        include R10K::Action::Visitor

        private

        def read_purge_allowlist (whitelist, allowlist)
          whitelist_has_content = !whitelist.empty?
          allowlist_has_content = !allowlist.empty?
          case
          when whitelist_has_content == false && allowlist_has_content == false
            []
          when whitelist_has_content && allowlist_has_content
            raise R10K::Error.new "Values found for both purge_whitelist and purge_allowlist. Setting " <<
                                  "purge_whitelist is deprecated, please only use purge_allowlist."
          when allowlist_has_content
            allowlist
          else
            logger.warn "Setting purge_whitelist is deprecated; please use purge_allowlist instead."
            whitelist
          end
        end

        def visit_deployment(deployment)
          # Ensure that everything can be preloaded. If we cannot preload all
          # sources then we can't fully enumerate all environments which
          # could be dangerous. If this fails then an exception will be raised
          # and execution will be halted.
          if @settings.dig(:overrides, :environments, :preload_environments)
            deployment.preload!
            deployment.validate!
          end

          undeployable = undeployable_environment_names(deployment.environments, @settings.dig(:overrides, :environments, :requested_environments))
          if !undeployable.empty?
            @visit_ok = false
            logger.error _("Environment(s) \'%{environments}\' cannot be found in any source and will not be deployed.") % {environments: undeployable.join(", ")}
          end

          yield

          if @settings.dig(:overrides, :purging, :purge_levels).include?(:deployment)
            logger.debug("Purging unmanaged environments for deployment...")
            deployment.sources.each do |source|
              source.reload!
            end
            deployment.purge!
          end
        ensure
          if (postcmd = @settings[:postrun])
            if postcmd.grep('$modifiedenvs').any?
              envs = deployment.environments.map { |e| e.dirname }
              requested_envs = @settings.dig(:overrides, :environments, :requested_environments)
              envs.reject! { |e| !requested_envs.include?(e) } if requested_envs.any?
              postcmd = postcmd.map { |e| e.gsub('$modifiedenvs', envs.join(' ')) }
            end
            subproc = R10K::Util::Subprocess.new(postcmd)
            subproc.logger = logger
            subproc.execute
          end
        end

        def visit_source(source)
          yield
        end

        def visit_environment(environment)
          requested_envs = @settings.dig(:overrides, :environments, :requested_environments)
          if !(requested_envs.empty? || requested_envs.any? { |name| environment.dirname == name })
            logger.debug1(_("Environment %{env_dir} does not match environment name filter, skipping") % {env_dir: environment.dirname})
            return
          end

          started_at = Time.new
          @environment_ok = true

          status = environment.status
          logger.info _("Deploying environment %{env_path}") % {env_path: environment.path}

          environment.sync
          logger.info _("Environment %{env_dir} is now at %{env_signature}") % {env_dir: environment.dirname, env_signature: environment.signature}

          if status == :absent || @settings.dig(:overrides, :modules, :deploy_modules)
            if status == :absent
              logger.debug(_("Environment %{env_dir} is new, updating all modules") % {env_dir: environment.dirname})
            end

            previous_ok = @visit_ok
            @visit_ok = true

            environment.deploy

            @environment_ok = @visit_ok
            @visit_ok &&= previous_ok
          end


          if @settings.dig(:overrides, :purging, :purge_levels).include?(:environment)
            if @visit_ok
              logger.debug("Purging unmanaged content for environment '#{environment.dirname}'...")
              environment.purge!(:recurse => true, :whitelist => environment.whitelist(@settings.dig(:overrides, :purging, :purge_allowlist)))
            else
              logger.debug("Not purging unmanaged content for environment '#{environment.dirname}' due to prior deploy failures.")
            end
          end

          if @settings.dig(:overrides, :environments, :generate_types)
            if @environment_ok
              logger.debug("Generating puppet types for environment '#{environment.dirname}'...")
              environment.generate_types!
            else
              logger.debug("Not generating puppet types for environment '#{environment.dirname}' due to puppetfile failures.")
            end
          end

          write_environment_info!(environment, started_at, @visit_ok)
        end

        def write_environment_info!(environment, started_at, success)
          module_deploys =
            begin
              environment.modules.map do |mod|
                props = mod.properties
                {
                  name: mod.name,
                  version: props[:expected],
                  sha: props[:type] == :git ? props[:actual] : nil
                }
              end
            rescue
              logger.debug("Unable to get environment module deploy data for .r10k-deploy.json at #{environment.path}")
              []
            end

          # make this file write as atomic as possible in pure ruby
          final   = "#{environment.path}/.r10k-deploy.json"
          staging = "#{environment.path}/.r10k-deploy.json~"
          File.open(staging, 'w') do |f|
            deploy_info = environment.info.merge({
              :started_at => started_at,
              :finished_at => Time.new,
              :deploy_success => success,
              :module_deploys => module_deploys,
            })

            f.puts(JSON.pretty_generate(deploy_info))
          end
          FileUtils.mv(staging, final)
        end

        def undeployable_environment_names(environments, expected_names)
          if expected_names.empty?
            []
          else
            known_names = environments.map(&:dirname)
            expected_names - known_names
          end
        end

        def allowed_initialize_opts
          super.merge(puppetfile: :modules,
                      modules: :self,
                      cachedir: :self,
                      incremental: :self,
                      'no-force': :self,
                      'exclude-spec': :self,
                      'generate-types': :self,
                      'puppet-path': :self,
                      'puppet-conf': :self,
                      'private-key': :self,
                      'oauth-token': :self,
                      'default-branch-override': :self,
                      'github-app-id': :self,
                      'github-app-key': :self,
                      'github-app-ttl': :self)
        end
      end
    end
  end
end
