require 'forwardable'
require 'r10k/logging'
require 'r10k/git/cache'

module R10K
module Git
class WorkingDir < R10K::Git::Repository
  # Implements sparse git repositories with shared objects
  #
  # Working directory instances use the git alternatives object store, so that
  # working directories only contain checked out files and all object files are
  # shared.

  include R10K::Logging

  extend Forwardable

  # @!attribute [r] cache
  #   @return [R10K::Git::Cache] The object cache backing this working directory
  attr_reader :cache

  # @!attribute [r] ref
  #   @return [String] The git reference to use check out in the given directory
  attr_reader :ref

  # Instantiates a new git synchro and optionally prepares for caching
  #
  # @param [String] ref
  # @param [String] remote
  # @param [String] basedir
  # @param [String] dirname
  def initialize(ref, remote, basedir, dirname = nil)
    @ref     = ref
    @remote  = remote
    @basedir = basedir
    @dirname = dirname || ref

    @full_path = File.join(@basedir, @dirname)

    @cache = R10K::Git::Cache.new(@remote)
  end

  # Synchronize the local git repository.
  def sync
    # TODO stop forcing a sync every time.
    @cache.sync

    if cloned?
      fetch
    else
      clone
    end
    reset
  end

  # Determine if repo has been cloned into a specific dir
  #
  # @return [true, false] If the repo has already been cloned
  def cloned?
    File.directory? git_dir
  end

  private

  def set_cache_remote
    # XXX This is crude but it'll ensure that the right remote is used for
    # the cache.
    if remote_url('cache') == @cache.path
      logger.debug1 "Git repo #{@full_path} cache remote already set correctly"
    else
      git "remote set-url cache #{@cache.path}", :path => @full_path
    end
  end

  # Perform a non-bare clone of a git repository.
  def clone
    # We do the clone against the target repo using the `--reference` flag so
    # that doing a normal `git pull` on a directory will work.
    git "clone --reference #{@cache.path} #{@remote} #{@full_path}"
    git "remote add cache #{@cache.path}", :path => @full_path
  end

  def fetch
    set_cache_remote
    git "fetch --prune cache", :path => @full_path
  end

  # Reset a git repo with a working directory to a specific ref
  def reset
    commit  = cache.rev_parse(@ref)
    current = rev_parse('HEAD')

    if commit == current
      logger.debug1 "Git repo #{@full_path} is already at #{commit}, no need to reset"
      return
    end

    begin
      git "reset --hard #{commit}", :path => @full_path
    rescue R10K::ExecutionFailure => e
      logger.error "Unable to locate commit object #{commit} in git repo #{@full_path}"
      raise
    end
  end

  # Resolve a ref to a commit hash
  #
  # @param [String] ref
  #
  # @return [String] The dereferenced hash of `ref`
  def rev_parse(ref)
    commit = git "rev-parse #{ref}^{commit}", :path => @full_path
    commit.chomp
  rescue R10K::ExecutionFailure => e
    logger.error "Could not resolve ref #{ref.inspect} for git repo #{@full_path}"
    raise
  end

  # @param [String] name The remote to retrieve the URl for
  # @return [String] The git remote URL
  def remote_url(remote_name)
    output = git "remote -v", :path => @full_path

    remotes = {}

    output.each_line do |line|
      if mdata = line.match(/^(\S+)\s+(\S+)\s+\(fetch\)/)
        name   = mdata[1]
        remote = mdata[2]
        remotes[name] = remote
      end
    end

    remotes[remote_name]
  end

  def git_dir
    File.join(@full_path, '.git')
  end
end
end
end
