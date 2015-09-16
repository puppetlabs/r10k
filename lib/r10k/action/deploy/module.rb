require 'r10k/util/setopts'
require 'r10k/deployment'
require 'r10k/action/visitor'
require 'r10k/logging'
require 'r10k/deployment/write_lock'

module R10K
  module Action
    module Deploy
      class Module

        include R10K::Logging
        include R10K::Util::Setopts
        include R10K::Deployment::WriteLock

        def initialize(opts, argv)
          @opts = opts
          @argv = argv
          setopts(opts, {
            :config      => :self,
            :environment => nil,
            :trace       => :self
          })

          @purge = true
        end

        def call
          @visit_ok = true

          deployment = R10K::Deployment.load_config(@config)
          check_write_lock!(deployment.config.settings)

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
      end
    end
  end
end
