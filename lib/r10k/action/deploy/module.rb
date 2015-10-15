require 'r10k/deployment'
require 'r10k/action/visitor'
require 'r10k/action/base'
require 'r10k/deployment/write_lock'

module R10K
  module Action
    module Deploy
      class Module < R10K::Action::Base

        include R10K::Deployment::WriteLock

        def call
          @visit_ok = true

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
            logger.debug1("Only updating modules in environment #{@opts[:environment]}, skipping environment #{environment.path}")
          else
            logger.debug1("Updating modules #{@argv.inspect} in environment #{environment.path}")
            yield
          end
        end

        def visit_puppetfile(puppetfile)
          puppetfile.load
          yield
        end

        def visit_module(mod)
          if @argv.include?(mod.name)
            logger.info "Deploying module #{mod.path}"
            mod.sync
          else
            logger.debug1("Only updating modules #{@argv.inspect}, skipping module #{mod.name}")
          end
        end

        def allowed_initialize_opts
          super.merge(environment: true)
        end
      end
    end
  end
end
