require 'r10k/deployment'
require 'r10k/action/visitor'
require 'r10k/action/base'
require 'r10k/action/deploy/deploy_helpers'

module R10K
  module Action
    module Deploy
      class Module < R10K::Action::Base

        include R10K::Action::Deploy::DeployHelpers

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
          if @opts[:environment] && (@opts[:environment] != environment.dirname)
            logger.debug1(_("Only updating modules in environment %{opt_env} skipping environment %{env_path}") % {opt_env: @opts[:environment], env_path: environment.path})
          else
            logger.debug1(_("Updating modules %{modules} in environment %{env_path}") % {modules: @argv.inspect, env_path: environment_path})
            yield
          end
        end

        def visit_puppetfile(puppetfile)
          puppetfile.load
          yield
        end

        def visit_module(mod)
          if @argv.include?(mod.name)
            logger.info _("Deploying module %{mod_path}") % {mod_path: mod.path}
            mod.sync
          else
            logger.debug1(_("Only updating modules %{modules}, skipping module %{mod_name}") % {modules: @argv.inspect, mod_name: mod.name})
          end
        end

        def allowed_initialize_opts
          super.merge(environment: true)
        end
      end
    end
  end
end
