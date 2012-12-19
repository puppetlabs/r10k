require 'r10k'
require 'cocaine'
require 'logger'


module R10K::Synchro; end

class R10K::Synchro::Git

  class << self
    attr_accessor :cache_root
  end

  attr_reader :source

  def initialize(source)
    @source = source

    if (cache_root = self.class.cache_root)
      @cache_path = File.join(cache_root, @source.gsub(/[^@\w-]/, '-'))
    end
  end

  # loldox
  #
  # @param [String] path The destination path for the files
  # @param [String] ref The git ref to instantiate at the destination path
  def sync(path, ref)

    path = File.expand_path(path)

    if File.directory?(File.join(path, '.git'))
      fetch(path)
      reset(path, ref)
    else
      clone(path)
      reset(path, ref)
    end
  end

  def cache
    if @cache_path and File.directory? @cache_path
      git "fetch", @cache_path
    else
      FileUtils.mkdir_p File.join(@cache_path)
      git "clone --mirror #{@source} #{cachedir}"
    end
  end

  private

  def clone(path)
    if @cache_path and File.directory? @cache_path
      git "clone --reference #{@cache_path} #{@source} #{path}"
    else
      git "clone #{@source} #{path}"
    end
  end

  def fetch(path)
    if @cache_path and File.directory? @cache_path
      git "--git-dir #{@cache_path} fetch"
    end
    git "fetch", path
  end

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
