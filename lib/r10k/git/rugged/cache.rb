require 'r10k/git/rugged'
require 'r10k/git/cache'

class R10K::Git::Rugged::Cache < R10K::Git::Cache

  @instance_cache = R10K::InstanceCache.new(self)

  def self.bare_repository
    R10K::Git::Rugged::BareRepository
  end

  # Update the remote URL if the cache differs from the current configuration
  def sync!
    if cached? && @repo.remotes['origin'] != @remote
      @repo.update_remote(@remote)
    end
    super
  end
end
