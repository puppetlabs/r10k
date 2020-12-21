require 'r10k/util/setopts'
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

        attr_reader :force

        def initialize(opts, argv, settings = nil)
          settings ||= {}
          @purge_levels = settings.fetch(:deploy, {}).fetch(:purge_levels, [])
          @user_purge_whitelist = settings.fetch(:deploy, {}).fetch(:purge_whitelist, [])
          @generate_types = settings.fetch(:deploy, {}).fetch(:generate_types, false)

          super

          # @force here is used to make it easier to reason about
          @force = !@no_force
          @argv = @argv.map { |arg| arg.gsub(/\W/,'_') }
        end

        def call
          @visit_ok = true

          expect_config!
          credentials = extract_credentials!
          deployment = R10K::Deployment.new(@settings, credentials)
          check_write_lock!(@settings)

          deployment.accept(self)
          @visit_ok
        end

        include R10K::Action::Visitor

        private

        def extract_credentials!
          if @sshkey_path && @token_path
            raise R10K::Error, "Cannot specify both an SSH key and a token to use with this deploy."
          end

          if @sshkey_path
            if File.exists?(@sshkey_path)
              { sshkey_path: @sshkey_path }
            else
              raise R10K::Error, _("{%path} does not exist, cannot load SSH key") % { path: @sshkey_path }
            end
          elsif @token_path
            if @token_path == '-'
              token = $stdin.read
            elsif File.exists?(@token_path)
              token = File.read(@token_path).strip
            else
              raise R10K::Error, _("{%path} does not exist, cannot load OAuth token") % { path: @token_path }
            end

            unless valid_token?(token)
              raise R10K::Error, _("Supplied token contains invalid characters.")
            end

            { token: token }
          end
        end

        # This regex is the only real requirement for OAuth token format,
        # per https://www.oauth.com/oauth2-servers/access-tokens/access-token-response/
        def valid_token?(token)
          return token =~ /^[\w\-\.~\+\/]+$/
        end

        def visit_deployment(deployment)
          # Ensure that everything can be preloaded. If we cannot preload all
          # sources then we can't fully enumerate all environments which
          # could be dangerous. If this fails then an exception will be raised
          # and execution will be halted.
          deployment.preload!
          deployment.validate!

          undeployable = undeployable_environment_names(deployment.environments, @argv)
          if !undeployable.empty?
            @visit_ok = false
            logger.error _("Environment(s) \'%{environments}\' cannot be found in any source and will not be deployed.") % {environments: undeployable.join(", ")}
          end

          yield

          if @purge_levels.include?(:deployment)
            logger.debug("Purging unmanaged environments for deployment...")
            deployment.purge!
          end
        ensure
          if (postcmd = @settings[:postrun])
            if postcmd.grep('$modifiedenvs').any?
              envs = deployment.environments.map { |e| e.dirname }
              envs.reject! { |e| !@argv.include?(e) } if @argv.any?
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
          if !(@argv.empty? || @argv.any? { |name| environment.dirname == name })
            logger.debug1(_("Environment %{env_dir} does not match environment name filter, skipping") % {env_dir: environment.dirname})
            return
          end

          started_at = Time.new
          @environment_ok = true

          status = environment.status
          logger.info _("Deploying environment %{env_path}") % {env_path: environment.path}

          environment.sync
          logger.info _("Environment %{env_dir} is now at %{env_signature}") % {env_dir: environment.dirname, env_signature: environment.signature}

          if status == :absent || @puppetfile
            if status == :absent
              logger.debug(_("Environment %{env_dir} is new, updating all modules") % {env_dir: environment.dirname})
            end

            previous_ok = @visit_ok
            @visit_ok = true
            yield
            @environment_ok = @visit_ok
            @visit_ok &&= previous_ok
          end

          if @purge_levels.include?(:environment)
            if @visit_ok
              logger.debug("Purging unmanaged content for environment '#{environment.dirname}'...")
              environment.purge!(:recurse => true, :whitelist => environment.whitelist(@user_purge_whitelist))
            else
              logger.debug("Not purging unmanaged content for environment '#{environment.dirname}' due to prior deploy failures.")
            end
          end

          if @generate_types
            if @environment_ok
              logger.debug("Generating puppet types for environment '#{environment.dirname}'...")
              environment.generate_types!
            else
              logger.debug("Not generating puppet types for environment '#{environment.dirname}' due to puppetfile failures.")
            end
          end

          write_environment_info!(environment, started_at, @visit_ok)
        end

        def visit_puppetfile(puppetfile)
          puppetfile.load(@opts[:'default-branch-override'])

          yield

          if @purge_levels.include?(:puppetfile)
            logger.debug("Purging unmanaged Puppetfile content for environment '#{puppetfile.environment.dirname}'...")
            puppetfile.purge!
          end
        end

        def visit_module(mod)
          logger.info _("Deploying %{origin} content %{path}") % {origin: mod.origin, path: mod.path}
          mod.sync(force: @force)
        end

        def write_environment_info!(environment, started_at, success)
          module_deploys = []
          begin
            environment.modules.each do |mod|
              name = mod.name
              version = mod.version
              sha = mod.repo.head rescue nil
              module_deploys.push({:name => name, :version => version, :sha => sha})
            end
          rescue
            logger.debug("Unable to get environment module deploy data for .r10k-deploy.json at #{environment.path}")
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
          super.merge(puppetfile: :self,
                      cachedir: :self,
                      'no-force': :self,
                      'generate-types': :self,
                      'puppet-path': :self,
                      'puppet-conf': :self,
                      'sshkey-path': :self,
                      'token-path': :self,
                      'default-branch-override': :self)
        end
      end
    end
  end
end
