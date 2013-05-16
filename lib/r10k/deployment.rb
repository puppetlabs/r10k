require 'r10k'
require 'r10k/deployment/source'
require 'r10k/deployment/config'

require 'yaml'

module R10K
class Deployment
  # Model a full installation of module directories and modules.

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

    load_environments
  end

  def fetch_sources
    sources.each do |source|
      source.fetch_remote
    end
    load_environments
  end

  # Lazily load all sources
  #
  # This instantiates the @_sources instance variable, but should not be
  # used directly as it could be legitimately unset if we're doing lazy
  # loading.
  #
  # @return [Array<R10K::Deployment::Source>] All repository sources
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
  # @return [Array<R10K::Deployment::Environment>] All enviroments across
  #   all sources
  def environments
    load_environments if @_environments.nil?
    @_environments
  end

  private

  def load_sources
    @_sources = @config.setting(:sources).map do |(name, hash)|
      R10K::Deployment::Source.vivify(name, hash)
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
