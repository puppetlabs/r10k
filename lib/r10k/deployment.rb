require 'r10k'
require 'r10k/deployment/source'
require 'r10k/config'

require 'yaml'

module R10K
class Deployment
  # Model a full installation of module directories and modules.

  def initialize
    @config = R10K::Config.new
    @config.load_config
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
end
end
