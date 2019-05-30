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
    proxy = R10K::Git.get_proxy_for_remote(remote)

    R10K::Git.with_proxy(proxy) do
      git ['clone', '--no-hardlinks', '--mirror', remote, git_dir.to_s]
    end
  end

  def fetch(remote_name='origin')
    remote = remotes[remote_name]
    proxy = R10K::Git.get_proxy_for_remote(remote)

    R10K::Git.with_proxy(proxy) do
      git ['fetch', remote_name, '--prune'], :git_dir => git_dir.to_s
    end
  end

  def exist?
    @path.exist?
  end
end
