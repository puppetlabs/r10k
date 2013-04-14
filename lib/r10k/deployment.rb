require 'r10k'
require 'r10k/deployment/source'
require 'r10k/deployment/config'

require 'yaml'

module R10K
class Deployment
  # Model a full installation of module directories and modules.

  def initialize(config)
    @config = config
  end

  # @return [Array<R10K::Deployment::Source>] All sources for this deployment
  def sources
    sources = []
    @config.setting(:sources).each_pair do |name, source_config|
      remote  = source_config[:remote]
      basedir = source_config[:basedir]
      sources << R10K::Deployment::Source.new(name, remote, basedir)
    end

    sources
  end

  # @return [Array<R10K::Deployment::Environments>] All environments across all sources
  def environments
    envs = []
    sources.each do |source|
      source.fetch_environments
      envs += source.environments
    end
    envs
  end
end
end
