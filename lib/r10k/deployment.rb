require 'r10k/source'
require 'set'

module R10K
  # A deployment models the entire state of the configuration that a Puppet
  # master can use. It contains a set of sources that can produce environments
  # and manages the contents of directories where environments are deployed.
  #
  # @api private
  class Deployment

    require 'r10k/deployment/environment'
    require 'r10k/deployment/basedir'
    require 'r10k/deployment/source'
    require 'r10k/deployment/config'

    # Generate a deployment object based on a config
    #
    # @param path [String] The path to the deployment config
    # @return [R10K::Deployment] The deployment loaded with the given config
    def self.load_config(path)
      config = R10K::Deployment::Config.new(path)
      new(config)
    end

    def initialize(config)
      @config = config
    end

    def preload!
      sources.each(&:preload!)
    end
    alias fetch_sources preload!

    # Lazily load all sources
    #
    # This instantiates the @_sources instance variable, but should not be
    # used directly as it could be legitimately unset if we're doing lazy
    # loading.
    #
    # @return [Array<R10K::Source::Base>] All repository sources
    #   specified in the config
    def sources
      load_sources if @_sources.nil?
      @_sources
    end

    # Lazily load all environments
    #
    # This instantiates the @_environments instance variable, but should not be
    # used directly as it could be legitimately unset if we're doing lazy
    # loading.
    #
    # @return [Array<R10K::Environment::Base>] All enviroments across
    #   all sources
    def environments
      load_environments if @_environments.nil?
      @_environments
    end

    # @return [Set<String>] The paths used by all contained sources
    def paths
      paths = Set.new
      sources.each do |source|
        paths.add(source.basedir)
      end
      paths
    end

    private

    def load_sources
      sources = @config.setting(:sources)
      @_sources = sources.map do |(name, hash)|
        R10K::Source.from_hash(name, hash)
      end
    end

    def load_environments
      @_environments = []
      sources.each do |source|
        @_environments += source.environments
      end
    end
  end
end
