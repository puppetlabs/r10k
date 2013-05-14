require 'r10k'
require 'r10k/deployment/source'
require 'r10k/deployment/config'

require 'yaml'

module R10K
class Deployment
  # Model a full installation of module directories and modules.

  # @!attribute [r] sources
  #   @return [Array<R10K::Deployment::Source>] All repository sources
  #     specified in the config
  attr_reader :sources

  # @!attribute [r] environments
  #   @return [Array<R10K::Deployment::Environment>] All enviroments
  #     across all sources
  attr_reader :environments

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

    load_sources
    load_environments
  end

  def fetch_sources
    @sources.each do |source|
      source.fetch_remote
    end
    load_environments
  end

  private

  def load_sources
    @sources = []
    @config.setting(:sources).each_pair do |name, source_config|
      remote  = source_config[:remote]
      basedir = source_config[:basedir]
      @sources << R10K::Deployment::Source.new(name, remote, basedir)
    end
  end

  # Enumerate all sources and collect the environments they contain
  def load_environments
    @environments = []
    @sources.each do |source|
      @environments += source.environments
    end
  end
end
end
