require 'r10k/git/cache'
require 'r10k/root'

module R10K
class Deployment
class Source
  # Represents a git repository to map branches to environments

  # @!attribute [r] source
  #   @return [String] The git remote to use for environments
  attr_reader :remote

  # @!attribute [r] basedir
  #   @return [String] The base directory to deploy the environments into
  attr_reader :basedir

  # @!attribute [r] environments
  #   @return [Array<R10K::Deployment::Environment>] All environments for this source
  attr_reader :environments

  def initialize(remote, basedir)
    @remote  = remote
    @basedir = basedir
    @cache   = R10K::Git::Cache.new(@remote)

    @environments = []
  end

  # Get the latest list of branches for this source.
  def fetch_environments
    @cache.sync

    @environments = @cache.branches.map do |branch|
      R10K::Root.new({
        :remote  => @remote,
        :basedir => @basedir,
        :ref     => branch,
      })
    end
  end
end
end
end
