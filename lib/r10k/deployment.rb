require 'r10k/source'
require 'r10k/util/basedir'
require 'r10k/errors'
require 'set'

module R10K
  # A deployment models the entire state of the configuration that a Puppet
  # master can use. It contains a set of sources that can produce environments
  # and manages the contents of directories where environments are deployed.
  #
  # @api private
  class Deployment

    require 'r10k/deployment/config'

    # Generate a deployment object based on a config
    #
    # @deprecated
    #
    # @param path [String] The path to the deployment config
    # @return [R10K::Deployment] The deployment loaded with the given config
    def self.load_config(path, overrides={})
      config = R10K::Deployment::Config.new(path, overrides)
      new(config)
    end

    # @!attribute [r] config
    #   @return [R10K::Deployment::Config]
    attr_reader :config

    def initialize(config, credentials = {})
      @config = config
      @credentials = credentials
    end

    def preload!
      sources.each(&:preload!)
    end

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

    # @return [Array<String>] The paths used by all contained sources
    def paths
      paths_and_sources.keys
    end

    # @return [Hash<String, Array<R10K::Source::Base>]
    def paths_and_sources
      pathmap = Hash.new { |h, k| h[k] = [] }
      sources.each { |source| pathmap[source.basedir] << source }
      pathmap
    end

    # Remove unmanaged content from all source paths
    def purge!
      paths_and_sources.each_pair do |path, sources_at_path|
        R10K::Util::Basedir.new(path, sources_at_path).purge!
      end
    end

    def validate!
      hash = {}
      sources.each do |source|
        source.environments.each do |environment|
          if hash.key?(environment.path)
            osource, oenvironment = hash[environment.path]
            msg = _("Environment collision at %{env_path} between %{source}:%{env_name} and %{osource}:%{oenv_name}") % 
              {env_path: environment.path,
               source: source.name,
               env_name: environment.name,
               osource: osource.name,
               oenv_name: oenvironment.name}

            raise R10K::Error, msg
          else
            hash[environment.path] = [source, environment]
          end
        end
      end
    end

    def accept(visitor)
      visitor.visit(:deployment, self) do
        sources.each do |source|
          source.accept(visitor)
        end
      end
    end

    private

    def load_sources
      sources = @config[:sources]
      if sources.nil? || sources.empty?
        raise R10K::Error, _("Unable to load sources; the supplied configuration does not define the 'sources' key")
      end
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
