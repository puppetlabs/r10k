require 'r10k/git/cache'
require 'r10k/deployment/environment'
require 'r10k/util/purgeable'

module R10K
class Deployment
class Basedir
  # Represents a directory containing environments

  def initialize(path,deployment)
    @path       = path
    @deployment = deployment
  end

  include R10K::Util::Purgeable

  # Return the path of the basedir
  # @note This implements a required method for the Purgeable mixin
  # @return [String]
  def managed_directory
    @path
  end

  # List all environments that should exist in this basedir
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    @keepers = []
    @deployment.sources.each do |source|
      next unless source.managed_directory == @path
      @keepers += source.desired_contents
    end
    @keepers
  end

end
end
end
