require 'r10k/git'
require 'r10k/git/alternates'
require 'r10k/git/shellgit/base_repository'

# Manage a non-bare Git repository
class R10K::Git::ShellGit::WorkingRepository < R10K::Git::ShellGit::BaseRepository

  # @attribute [r] path
  #   @return [Pathname]
  attr_reader :path

  # @return [Pathname] The path to the Git directory inside of this repository
  def git_dir
    @path + '.git'
  end

  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))
  end

  # Clone this git repository
  #
  # @param remote [String] The Git remote to clone
  # @param opts [Hash]
  #
  # @options opts [String] :ref The git ref to check out on clone
  # @options opts [String] :reference A Git repository to use as an alternate object database
  #
  # @return [void]
  def clone(remote, opts = {})
    argv = ['clone', remote, @path.to_s]
    if opts[:reference]
      argv += ['--reference', opts[:reference]]
    end

    proxy = R10K::Git.get_proxy_for_remote(remote)

    R10K::Git.with_proxy(proxy) do
      git argv
    end

    if opts[:ref]
      checkout(opts[:ref])
    end
  end

  # Check out the given Git ref
  #
  # @param ref [String] The git reference to check out
  # @param opts [Hash] Optional hash of additional options.
  def checkout(ref, opts = {})
    # :force defaults to true
    if !opts.has_key?(:force) || opts[:force]
      force_opt = '--force'
    else
      force_opt = ''
    end

    git ['checkout', ref, force_opt], :path => @path.to_s
  end

  def fetch(remote_name='origin')
    remote = remotes[remote_name]
    proxy = R10K::Git.get_proxy_for_remote(remote)

    R10K::Git.with_proxy(proxy) do
      git ['fetch', remote_name, '--prune'], :path => @path.to_s
    end
  end

  def exist?
    @path.exist?
  end

  # @return [String] The currently checked out ref
  def head
    resolve('HEAD')
  end

  def alternates
    R10K::Git::Alternates.new(git_dir)
  end

  # @return [String] The origin remote URL
  def origin
    result = git(['config', '--get', 'remote.origin.url'], :path => @path.to_s, :raise_on_fail => false)
    if result.success?
      result.stdout
    end
  end

  # does the working tree have local modifications to tracked files?
  def dirty?
    # TODO
  end
end
