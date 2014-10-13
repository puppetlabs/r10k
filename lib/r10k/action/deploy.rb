require 'r10k/util/attempt'
require 'r10k/util/setopts'
require 'r10k/deployment'
require 'set'

module R10K
  module Action
    module Deploy
      class Environments

        include R10K::Util::Setopts

        def initialize(argv, opts)
          @argv = argv
          @opts = opts
          setopts(opts, {
            :config     => :self,
            :puppetfile => :self,
            :purge      => :self,
            :trace      => :nil
          })

          @purge = true
          @deployment = R10K::Deployment.load_config(@config)
        end

        def call
          attempt = R10K::Util::Attempt.new(@deployment, :trace => @opts[:trace])

          attempt.try do |deployment|
            # Ensure that everything can be preloaded. If we cannot preload all
            # sources then we can't fully enumerate all environments which
            # could be dangerous. If this fails then an exception will be raised
            # and execution will be halted.
            deployment.preload!

            if @purge
              paths = Set.new
              @deployment.sources.each { |source| paths.add(source.basedir) }
              paths.each do |path|
                R10K::Util::Basedir.new(path, @deployment.sources).purge!
              end
            end

            environments
          end

          attempt.try do |environment|
            environment.sync
            environment.modules if @puppetfile
          end.try do |mod|
            mod.sync
          end

          attempt.run
        end

        private

        def validate!
          if @argv.empty? && @deployment.environments.empty?
            raise R10K::R10KError, "No environments supplied in any sources, nothing to do"
          end
        end


        def environments
          @_environments ||= filter
        end

        def filter
          if @argv.empty?
            @deployment.environments
          else
            @deployment.environments.select do |env|
              @argv.any? { |name| env.dirname == name }
            end
          end
        end
      end
    end
  end
end
