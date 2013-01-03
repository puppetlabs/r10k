require 'r10k'
require 'r10k/errors'
require 'r10k/logging'

require 'systemu'
require 'fileutils'

module R10K::Synchro; end

class R10K::Synchro::Git
  # Define a thingy that can synchronize git repositories.
  #
  # This class is built to be a general purpose mechanism for syncing and
  # caching git repositories.
  #
  # Class instances are memoized based on the git remote path. This way if a
  # single git repository is instantiated multiple times, the object cache
  # will only be updated once.

  class << self
    attr_accessor :cache_root

    # @return [Hash<R10K::Synchro::Git>] A hash of memoized class instances
    def synchros
      @synchros ||= {}
    end

    # Memoize class instances and return existing instances.
    #
    # This allows objects to mark themselves as cached to prevent unnecessary
    # cache refreshes.
    #
    # @param [String] remote A git remote URL
    # @return [R10K::Synchro::Git]
    def new(remote)
      unless synchros[remote]
        obj = self.allocate
        obj.send(:initialize, remote)
        synchros[remote] = obj
      end
      synchros[remote]
    end
  end

  include R10K::Logging

  attr_reader :remote

  # Instantiates a new git synchro and optionally prepares for caching
  #
  # @param [String] remote A git remote URL
  def initialize(remote)
    @remote = remote

    if self.class.cache_root
      @cache_path = File.join(self.class.cache_root, @remote.gsub(/[^@\w\.-]/, '-'))
    end
  end

  # Synchronize the local git repository.
  #
  # @param [String] path The destination path for the files
  # @param [String] ref The git ref to instantiate at the destination path
  def sync(path, ref, options = {:update_cache => true})
    path = File.expand_path(path)
    sync_cache(options)

    if self.cloned?(path)
      fetch(path)
    else
      clone(path)
    end
    reset(path, ref)
  end

  # @return [TrueClass] if the git repository is cached
  def cached?
    @cache_path and File.directory? @cache_path
  end

  # Determine if repo has been cloned into a specific dir
  #
  # @param [String] dirname The directory to check
  #
  # @return [true, false] If the repo has already been cloned
  def cloned?(directory)
    File.directory?(File.join(directory, '.git'))
  end

  # Update the git object cache repository if it hasn't been done
  #
  # @return [true, nil] If the cache was actually updated
  def cache
    unless @cached
      cache!
      @cached = true
    end
  end

  # Force a cache refresh
  def cache!
    if cached?
      git "fetch --prune", :git_dir => @cache_path
    else
      mk_cache_root
      git "clone --mirror #{@remote} #{@cache_path}"
    end
  end

  # Retrieve a list of cached branches for the git repo associated with this
  # object.
  #
  # @return [Array<String>] A list of all cached remote branches
  def branches(options = {:update_cache => false})
    sync_cache(options)
    output = git "branch", :git_dir => @cache_path
    output.split("\n").map { |str| str[2..-1] }
  end

  private

  # XXX The use of options[:update_cache] is getting ugly. Consider refactor
  def sync_cache(options)
    if options[:update_cache]
      cache
    elsif not cached?
      puts "Forcing cache build for #{@remote}"
      cache
    end
  end

  def mk_cache_root
    cache_root = self.class.cache_root
    FileUtils.mkdir_p cache_root unless File.exist? cache_root
  end

  # Perform a non-bare clone of a git repository.
  #
  # If a cachedir is available and the repo is already cached, it will be
  # used as an object reference to speed up the clone.
  #
  # @param [String] path The directory to create the repo working directory
  def clone(path)
    if cached?
      git "clone --reference #{@cache_path} #{@remote} #{path}"
      git "remote add cache #{@cache_path}", path
    else
      FileUtils.mkdir_p path unless File.directory? path
      git "clone #{@remote} #{path}"
    end
  end

  def fetch(path)
    if cached?
      git "fetch --prune cache", :git_dir => path
    else
      git "fetch --prune origin", :git_dir => path
    end
  end

  # Reset a git repo with a working directory to a specific ref
  #
  # @param [String] path The path to the working directory of the git repo
  # @param [String] ref The git reference to reset to.
  def reset(path, ref)
    commit = resolve_commit(ref)

    begin
      git "reset --hard #{commit}", :git_dir => "#{path}/.git", :work_tree => path
    rescue R10K::ExecutionFailure => e
      logger.error "Unable to locate commit object #{commit} in git repo #{path}"
      raise
    end
  end

  # Resolve a ref to a commit hash
  #
  # @param [String] ref
  #
  # @return [String] The dereferenced hash of `ref`
  def resolve_commit(ref)
    git "rev-parse #{ref}^{commit}", :git_dir => @cache_path
  rescue R10K::ExecutionFailure => e
    logger.error "Could not resolve ref #{ref.inspect} for git cache #{@cache_path}"
    raise
  end

  # Wrap git commands
  #
  # @param [String] command_line_args The arguments for the git prompt
  # @param [Hash] opts
  #
  # @option opts [String] :git_dir
  # @option opts [String] :work_tree
  #
  # @return [String] The git command output
  def git(command_line_args, opts = {})
    args = %w{git}

    if opts[:git_dir]
      args << "--git-dir"
      args << opts[:git_dir]
    end

    if opts[:work_tree]
      args << "--work-tree"
      args << opts[:work_tree]
    end

    args << command_line_args

    cmd = args.join(' ')
    logger.info "Execute: #{cmd}"

    status, stdout, stderr = systemu(cmd)

    logger.debug "STDOUT: #{stdout}".green unless stdout.empty?
    logger.debug "STDERR: #{stderr}".red   unless stderr.empty?

    unless status == 0
      msg = "#{cmd.inspect} returned with non-zero exit value #{status.exitstatus}"
      e = R10K::ExecutionFailure.new(msg)
      e.exit_code = status
      e.stdout    = stdout
      e.stderr    = stderr
      raise e
    end
    stdout
  end
end
