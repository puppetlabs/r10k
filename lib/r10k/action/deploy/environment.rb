require 'r10k/util/attempt'
require 'r10k/util/setopts'
require 'r10k/deployment'
require 'r10k/logging'

module R10K
  module Action
    module Deploy
      class Environment

        include R10K::Util::Setopts
        include R10K::Logging

        def initialize(opts, argv)
          @opts = opts
          @argv = argv
          setopts(opts, {
            :config     => :self,
            :puppetfile => :self,
            :purge      => :self,
            :trace      => :nil
          })

          @purge  = true
        end

        def call
          @ok = true
          deployment = R10K::Deployment.load_config(@config)
          deployment.accept(self)
          @ok
        end

        def visit(type, other, &block)
          send("visit_#{type}", other, &block)
        rescue => e
          logger.error R10K::Errors::Formatting.format_exception(e, @trace)
          @ok = false
        end

        private

        def visit_deployment(deployment)
          # Ensure that everything can be preloaded. If we cannot preload all
          # sources then we can't fully enumerate all environments which
          # could be dangerous. If this fails then an exception will be raised
          # and execution will be halted.
          deployment.preload!

          yield

          deployment.purge! if @purge
        end

        def visit_source(source)
          yield
        end

        def visit_environment(environment)
          if !(@argv.empty? || @argv.any? { |name| environment.dirname == name })
            logger.debug1("Environment #{environment.dirname} does not match environment name filter, skipping")
            return
          end

          logger.info "Deploying environment #{environment.path}"
          # @todo only recurse by default if environment is new
          environment.sync
          yield if @puppetfile
        end

        def visit_puppetfile(puppetfile)
          puppetfile.load
          yield
          puppetfile.purge!
        end

        def visit_module(mod)
          logger.info "Deploying module #{mod.path}"
          mod.sync
        end
      end
    end
  end
end
