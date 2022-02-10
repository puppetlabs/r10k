require 'r10k/action/base'
require 'r10k/action/deploy/deploy_helpers'
require 'r10k/action/visitor'
require 'r10k/deployment'

module R10K
  module Action
    module Deploy
      class Module < R10K::Action::Base

        include R10K::Action::Deploy::DeployHelpers
        include R10K::Action::Visitor

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

          requested_env = @opts[:environment] ? [@opts[:environment].gsub(/\W/, '_')] : []
          @modified_envs = []

          @settings = @settings.merge({
            overrides: {
              environments: {
                requested_environments: requested_env,
                generate_types: @generate_types
              },
              modules: {
                default_ref: settings.dig(:git, :default_ref),
                exclude_spec: settings.dig(:deploy, :exclude_spec),
                pool_size: @settings[:pool_size] || 4,
                requested_modules: @argv.map.to_a,
                # force here is used to make it easier to reason about
                force: !@no_force
              },
              forge: {
                allow_puppetfile_override: settings.dig(:forge, :allow_puppetfile_override) || false
              },
              purging: {},
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

        private

        def visit_deployment(deployment)
          yield
        ensure
          if (postcmd = @settings[:postrun])
            if @modified_envs.any?
              envs_to_run = @modified_envs.join(' ')
              logger.debug _("Running postrun command for environments: %{envs_to_run}.") % { envs_to_run: envs_to_run }

              if postcmd.grep('$modifiedenvs').any?
                postcmd = postcmd.map { |e| e.gsub('$modifiedenvs', envs_to_run) }
              end

              subproc = R10K::Util::Subprocess.new(postcmd)
              subproc.logger = logger
              subproc.execute
            else
              logger.debug _("No environments were modified, not executing postrun command.")
            end
          end
        end

        def visit_source(source)
          yield
        end

        def visit_environment(environment)
          requested_envs = @settings.dig(:overrides, :environments, :requested_environments)
          if !requested_envs.empty? && !requested_envs.include?(environment.dirname)
            logger.debug1(_("Only updating modules in environment(s) %{opt_env} skipping environment %{env_path}") % {opt_env: requested_envs.inspect, env_path: environment.path})
          else
            logger.debug1(_("Updating modules %{modules} in environment %{env_path}") % {modules: @settings.dig(:overrides, :modules, :requested_modules).inspect, env_path: environment.path})

            updated_modules = environment.deploy

            # We actually synced a module in this env
            if !updated_modules.nil? && !updated_modules.empty?
              # Record modified environment for postrun command
              @modified_envs << environment.dirname

              if generate_types = @settings.dig(:overrides, :environments, :generate_types)
                logger.debug("Generating puppet types for environment '#{environment.dirname}'...")
                environment.generate_types!
              end
            end
          end
        end

        def allowed_initialize_opts
          super.merge(environment: true,
                      cachedir: :self,
                      'exclude-spec': :self,
                      'no-force': :self,
                      'generate-types': :self,
                      'puppet-path': :self,
                      'puppet-conf': :self,
                      'private-key': :self,
                      'oauth-token': :self,
                      'github-app-id': :self,
                      'github-app-key': :self,
                      'github-app-ttl': :self)
        end
      end
    end
  end
end
