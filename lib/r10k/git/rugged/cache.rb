require 'r10k/git/rugged'
require 'r10k/git/cache'

class R10K::Git::Rugged::Cache < R10K::Git::Cache

  @instance_cache = R10K::InstanceCache.new(self)

  def self.bare_repository
    R10K::Git::Rugged::BareRepository
  end
end
