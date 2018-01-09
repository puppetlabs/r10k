require 'r10k/git'
require 'r10k/git/alternates'
require 'r10k/git/shellgit/base_repository'

# Manage a non-bare Git repository
class R10K::Git::ShellGit::WorkingRepository < R10K::Git::ShellGit::BaseRepository

  # @attribute [r] path
  #   @return [Pathname]
  attr_reader :path

  # @attribute [r] git_dir
  #   @return [Pathname]
  attr_reader :git_dir

  def initialize(basedir, dirname, gitdirname = '.git')
    @path = Pathname.new(File.join(basedir, dirname)).cleanpath
    @git_dir = Pathname.new(File.join(basedir, dirname, gitdirname)).cleanpath
  end

  def git(cmd, opts = {})
    work_tree = opts.delete(:path) || @path.to_s
    path_opts = {:git_dir => @git_dir.to_s, :work_tree => work_tree}

    super(cmd, path_opts.merge(opts))
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
    clone_argv = ['clone', '--bare', '--single-branch', '-c', 'remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*', remote, @git_dir.to_s]
    if opts[:reference]
      clone_argv += ['--reference', opts[:reference]]
    end

    proxy = R10K::Git.get_proxy_for_remote(remote)

    R10K::Git.with_proxy(proxy) do
      git clone_argv
      git ['fetch', 'origin', '--prune']
    end

    if opts[:ref]
      checkout(opts[:ref])
    else
      checkout('HEAD')
    end
  end

  # Check out the given Git ref
  #
  # @param ref [String] The git reference to check out
  # @param opts [Hash] Optional hash of additional options.
  def checkout(ref, opts = {})
    argv = ['checkout', ref]

    # :force defaults to true
    if !opts.has_key?(:force) || opts[:force]
      argv << '--force'
    end

    git argv
  end

  def fetch(remote_name='origin')
    remote = remotes[remote_name]
    proxy = R10K::Git.get_proxy_for_remote(remote)

    R10K::Git.with_proxy(proxy) do
      git ['fetch', remote_name, '--prune']
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
    result = git(['config', '--get', 'remote.origin.url'], :raise_on_fail => false)
    if result.success?
      result.stdout
    end
  end

  # does the working tree have local modifications to tracked files?
  def dirty?
    result = git(['diff-index', '--exit-code', '--name-only', 'HEAD'], :raise_on_fail => false)

    if result.exit_code != 0
      dirty_files = result.stdout.split('\n')

      dirty_files.each do |file|
        logger.debug(_("Found local modifications in %{file_path}" % {file_path: File.join(@path, file)}))

        # Do this in a block so that the extra subprocess only gets invoked when needed.
        logger.debug1 { git(['diff-index', '-p', 'HEAD', file], :raise_on_fail => false).stdout }
      end

      return true
    else
      return false
    end
  end
end
