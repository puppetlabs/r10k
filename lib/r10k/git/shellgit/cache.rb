require 'r10k/git/shellgit'
require 'r10k/git/cache'

class R10K::Git::ShellGit::Cache < R10K::Git::Cache

  @instance_cache = R10K::InstanceCache.new(self)

  def self.bare_repository
    R10K::Git::ShellGit::BareRepository
  end
end
