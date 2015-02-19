require 'r10k/git'
require 'r10k/git/base_repository'
require 'r10k/logging'

# Create and manage Git bare repositories.
class R10K::Git::BareRepository < R10K::Git::BaseRepository

  # @return [Pathname] The path to this Git repository
  def git_dir
    @path
  end

  # @param basedir [String] The base directory of the Git repository
  # @param dirname [String] The directory name of the Git repository
  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))
  end

  def clone(remote)
    git ['clone', '--mirror', remote, git_dir.to_s]
  end

  def fetch
    git ['fetch', '--prune'], :git_dir => git_dir.to_s
  end

  def exist?
    @path.exist?
  end
end
