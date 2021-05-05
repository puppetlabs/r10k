require 'r10k/deployment'
require 'r10k/action/visitor'
require 'r10k/action/base'
require 'r10k/action/deploy/deploy_helpers'

module R10K
  module Action
    module Deploy
      class Module < R10K::Action::Base

        include R10K::Action::Deploy::DeployHelpers

        # Deprecated
        attr_reader :force

        attr_reader :settings

        def initialize(opts, argv, settings)

          super

          requested_env = @opts[:environment] ? [@opts[:environment].gsub(/\W/, '_')] : []

          @settings = @settings.merge({
            overrides: {
              environments: {
                requested_environments: requested_env,
                generate_types: @generate_types
              },
              modules: {
                requested_modules: @argv.map.to_a,
                # force here is used to make it easier to reason about
                force: !@no_force
              },
              purging: {},
              output: {}
            }
          })
        end

        def call
          @visit_ok = true

          expect_config!
          deployment = R10K::Deployment.new(@settings)
          check_write_lock!(@settings)

          deployment.accept(self)
          @visit_ok
        end

        include R10K::Action::Visitor

        private

        def visit_deployment(deployment)
          yield
        end

        def visit_source(source)
          yield
        end

        def visit_environment(environment)
          requested_envs = @settings.dig(:overrides, :environments, :requested_environments)
          if !requested_envs.empty? && requested_envs.include?(environment.dirname)
            logger.debug1(_("Only updating modules in environment(s) %{opt_env} skipping environment %{env_path}") % {opt_env: requested_envs.inspect, env_path: environment.path})
          else
            logger.debug1(_("Updating modules %{modules} in environment %{env_path}") % {modules: @settings.dig(:overrides, :modules, :requested_modules).inspect, env_path: environment.path})
            yield
          end
        end

        def visit_puppetfile(puppetfile)
          puppetfile.load
          yield
        end

        def visit_module(mod)
          mod.sync

          requested_mods = @settings.dig(:overrides, :modules, :requested_modules) || []
          if requested_mods.include?(mod.name) && mod.environment && @settings.dig(:overrides, :environments, :generate_types)
            logger.debug("Generating puppet types for environment '#{mod.environment.dirname}'...")
            mod.environment.generate_types!
          end
        end

        def allowed_initialize_opts
          super.merge(environment: true,
                      cachedir: :self,
                      'no-force': :self,
                      'generate-types': :self,
                      'puppet-path': :self,
                      'puppet-conf': :self,
                      'private-key': :self,
                      'oauth-token': :self)
        end
      end
    end
  end
end
