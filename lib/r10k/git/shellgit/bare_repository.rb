require 'r10k/git/shellgit'
require 'r10k/git/shellgit/base_repository'

# Create and manage Git bare repositories.
class R10K::Git::ShellGit::BareRepository < R10K::Git::ShellGit::BaseRepository

  # @param basedir [String] The base directory of the Git repository
  # @param dirname [String] The directory name of the Git repository
  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))
  end

  # @return [Pathname] The path to this Git repository
  def git_dir
    @path
  end

  # @return [Pathname] The path to the objects directory in this Git repository
  def objects_dir
    @path + "objects"
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

  def blob_at(treeish, path)
    result = git ['show', "#{treeish}:#{path}"], :git_dir => git_dir.to_s

    result.success? ? result.stdout.strip : nil
  end
end
