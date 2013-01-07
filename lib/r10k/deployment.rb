require 'r10k'
require 'r10k/config'
require 'r10k/synchro/git'
require 'yaml'

class R10K::Deployment
  # Model a full installation of module directories and modules.

  class << self
    def instance
      @myself ||= self.new
    end

    def config
      instance.config
    end

    def collection
      instance.collection
    end
  end

  def initialize
    @config = R10K::Config.new
  end

  def config
    @config
  end

  # Load up all module roots
  #
  # @return [Array<R10K::Root>]
  def environments
    collection.to_a
  end

  def collection
    @config.load_config unless @config.loaded?
    @collection ||= R10K::Deployment::EnvironmentCollection.new(@config)
    @collection
  end
end

require 'r10k/deployment/environment_collection'
