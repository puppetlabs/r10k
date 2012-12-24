require 'r10k'
require 'cocaine'
require 'logger'

module R10K::Synchro; end

class R10K::Synchro::Git

  class << self
    attr_accessor :cache_root
    attr_accessor :should_update_cache

    def should_update_cache
      if defined? @should_update_cache
        @should_update_cache
      else
        true
      end
    end

    def should_update_cache=(bool)
      @should_update_cache = !!(bool)
    end

    # @return [Hash<R10K::Synchro::Git>] A hash of the memoized instances
    def synchros
      @synchros ||= {}
    end

    # Memoize class instances and return existing instances.
    #
    # This allows objects to mark themselves as cached to prevent unnecessary
    # cache refreshes.
    #
    # @param [String] source A git remote URL
    # @return [R10K::Synchro::Git]
    def new(source)
      unless synchros[source]
        obj = self.allocate
        obj.send :initialize, source
        synchros[source] = obj
      end
      synchros[source]
    end
  end

  attr_reader :source

  # Instantiates a new git synchro and optionally prepares for caching
  #
  # @param [String] source A git remote URL
  def initialize(source)
    @source = source
    @should_update_cache = self.class.should_update_cache

    if self.class.cache_root
      @cache_path = File.join(self.class.cache_root, @source.gsub(/[^@\w-]/, '-'))
    end
  end

  # Synchronize the local git repository.
  #
  # @param [String] path The destination path for the files
  # @param [String] ref The git ref to instantiate at the destination path
  def sync(path, ref)
    path = File.expand_path(path)
    cache if should_update_cache?

    if File.directory?(File.join(path, '.git'))
      fetch(path)
    else
      clone(path)
    end

    reset(path, ref)
  end

  # @return [TrueClass] if the git repository is cached
  def has_cache?
    @cache_path and File.directory? @cache_path
  end

  def should_update_cache?
    @update_cache
  end

  def should_update_cache(bool)
    @update_cache = !!(bool)
  end

  # Ensure that the git repo cache is present and up to date
  def cache
    if has_cache?
      git "--git-dir #{@cache_path} fetch --prune"
    else
      FileUtils.mkdir_p File.dirname(File.join(@cache_path))
      git "clone --mirror #{@source} #{@cache_path}"
    end

    @update_cache = false
  end

  def branches
    cache
    output = git "--git-dir #{@cache_path} branch"
    output.split("\n").map { |str| str[2..-1] }
  end

  private

  # Perform a non-bare clone of a git repository.
  #
  # If a cachedir is available and the repo is already cached, it will be
  # used as an object reference to speed up the clone.
  #
  # @param [String] path The directory to create the repo working directory
  def clone(path)
    if has_cache?
      git "clone --reference #{@cache_path} #{@source} #{path}"
    elsif should_update_cache?
      cache
      git "clone --reference #{@cache_path} #{@source} #{path}"
    else
      git "clone #{@source} #{path}"
    end
  end

  def fetch(path)
    git "fetch --prune", path
  end

  # Reset a git repo with a working directory to a specific ref
  #
  # @param [String] path The path to the working directory of the git repo
  # @param [String] ref The git reference to reset to.
  def reset(path, ref)
    # THIS IS A TOTAL HACK.
    begin
      commit = git "rev-parse #{ref}^{commit}", path
    rescue Cocaine::ExitStatusError
      commit = "origin/#{ref}"
    end
    git "reset --hard #{commit}", path
    git "clean -f", path
  end

  logger = ::Logger.new(STDOUT)
  logger.datetime_format = "%I:%M %p"
  Cocaine::CommandLine.logger = logger


  def git(str, path = nil)
    git_str = path ? "git --work-tree #{path} --git-dir #{path}/.git" : "git"
    cmd = Cocaine::CommandLine.new("#{git_str} #{str}")
    cmd.run
  end
end
