require 'r10k/git/cache'
require 'r10k/deployment/environment'

module R10K
class Deployment
class Source
  # Represents a git repository to map branches to environments

  # @!attribute [r] name
  #   @return [String] The short name for the deployment source

  # @!attribute [r] source
  #   @return [String] The git remote to use for environments
  attr_reader :remote

  # @!attribute [r] basedir
  #   @return [String] The base directory to deploy the environments into
  attr_reader :basedir

  # @!attribute [r] environments
  #   @return [Array<R10K::Deployment::Environment>] All environments for this source
  attr_reader :environments

  def initialize(name, remote, basedir)
    @name    = name
    @remote  = remote
    @basedir = basedir

    @cache   = R10K::Git::Cache.new(@remote)
    @environments = []
  end

  # Get the latest list of branches for this source.
  def fetch_environments
    @cache.sync

    @environments = @cache.branches.map do |branch|
      R10K::Deployment::Environment.new(branch, @remote, @basedir)
    end
  end

  # Returns directories that don't map to branches
  #
  # @return [Array<String>] All stale directories
  def stale
    branches = @environments.map(&:name)

    existing_directories - branches
  end

  # @return [Array<String>] All existing directories
  def existing_directories
    directories = Dir.glob[File.join(@basedir, '*')].select do |entry|
      File.directory? entry
    end

    directories.select {|dir| File.basename dir}
  end
end
end
end
