require 'r10k/util/attempt'
require 'r10k/util/setopts'
require 'r10k/deployment'

module R10K
  module Action
    module Deploy
      class Module

        include R10K::Logging
        include R10K::Util::Setopts

        def initialize(opts, argv)
          @opts = opts
          @argv = argv
          setopts(opts, {
            :config      => :self,
            :environment => nil,
            :trace       => nil
          })

          @purge = true
          @deployment = R10K::Deployment.load_config(@config)
        end

        def call
          # @todo validation

          attempt = R10K::Util::Attempt.new(environments, :trace => @opts[:trace])

          attempt.try do |environment|
            logger.debug "Updating modules #{@argv.inspect} in environment #{environment.name}"
            environment.modules.select { |mod| @argv.any? { |name| mod.name == name } }
          end

          attempt.try do |mod|
            mod.sync
          end

          attempt.run

          attempt.ok?
        end

        private

        def environments
          @_environments ||= filter
        end

        def filter
          if @opts[:environment]
            @deployment.environments.select { |env| env.dirname = @opts[:environment] }
          else
            @deployment.environments
          end
        end
      end
    end
  end
end

