require 'r10k'
require 'cocaine'
require 'logger'


module R10K::Synchro; end

class R10K::Synchro::Git

  class << self
    attr_accessor :cache_root

    def synchros
      @synchros ||= {}
    end

    def new(source)
      if synchros[source]
        puts "Object cache hit on #{source}".green
      else
        puts "Object cache miss on #{source}".red
        obj = self.allocate
        obj.send :initialize, source
        synchros[source] = obj
      end
      synchros[source]
    end
  end

  attr_reader :source

  def initialize(source)
    @source = source

    if (cache_root = self.class.cache_root)
      @cache_path = File.join(cache_root, @source.gsub(/[^@\w-]/, '-'))
    end
  end

  # Synchronize the local git repository.
  #
  # @param [String] path The destination path for the files
  # @param [String] ref The git ref to instantiate at the destination path
  def sync(path, ref)
    path = File.expand_path(path)
    cache if should_cache?

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

  def should_cache?
    !!(self.class.cache_root)
  end

  # Ensure that the git repo cache is present and up to date
  def cache
    if @cached
      return
    end

    if has_cache?
      git "--git-dir #{@cache_path} fetch"
    else
      FileUtils.mkdir_p File.dirname(File.join(@cache_path))
      git "clone --mirror #{@source} #{@cache_path}"
    end

    @cached = true
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
    elsif should_cache?
      cache
      git "clone --reference #{@cache_path} #{@source} #{path}"
    else
      git "clone #{@source} #{path}"
    end
  end

  def fetch(path)
    git "fetch", path
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
