require 'r10k/logging'
require 'r10k/git/repository'

module R10K
module Git
class Cache < R10K::Git::Repository
  # Mirror a git repository for use shared git object repositories
  #
  # @see man git-clone(1)

  class << self

    # @!attribute [r] cache_root
    #   @return [String] The directory to use as the cache.
    attr_writer :cache_root

    def cache_root
      @cache_root
    end

    # Memoize class instances and return existing instances.
    #
    # This allows objects to mark themselves as cached to prevent unnecessary
    # cache refreshes.
    #
    # @param [String] remote A git remote URL
    # @return [R10K::Synchro::Git]
    def new(remote)
      @repos ||= {}
      unless @repos[remote]
        obj = self.allocate
        obj.send(:initialize, remote)
        @repos[remote] = obj
      end
      @repos[remote]
    end

    def clear!
      @repos = {}
    end
  end

  include R10K::Logging

  # @!attribute [r] remote
  #   @return [String] The git repository remote
  attr_reader :remote

  # @!attribute [r] cache_root
  #   Where to keep the git object cache. Defaults to ~/.r10k/git if a class
  #   level value is not set.
  #   @return [String] The directory to use as the cache
  attr_reader :cache_root

  # @!attribute [r] path
  #   @return [String] The path to the git cache repository
  attr_reader :path

  # @param [String] remote
  # @param [String] cache_root
  def initialize(remote)
    @remote = remote

    @cache_root = self.class.cache_root || default_cache_root

    @path = File.join(@cache_root, sanitized_dirname)
  end

  def sync
    if @synced
      # XXX This gets really spammy. Might be good to turn it on later, but for
      # general work it's way much.
      #logger.debug "#{@remote} already synced this run, not syncing again"
    else
      sync!
      @synced = true
    end
  end

  def sync!
    if cached?
      # XXX This gets really spammy. Might be good to turn it on later, but for
      # general work it's way much.
      #logger.debug "Updating existing cache at #{@path}"
      git "fetch --prune", :git_dir => @path
    else
      logger.debug "Creating new git cache for #{@remote.inspect}"
      FileUtils.mkdir_p cache_root unless File.exist? @cache_root
      git "clone --mirror #{@remote} #{@path}"
    end
  end

  # @return [Array<String>] A list the branches for the git repository
  def branches
    output = git "branch", :git_dir => @path
    output.split("\n").map do |str|
      # the `git branch` command returns output like this:
      # <pre>
      #   0.11.x
      #   0.12.x
      # * master
      #   passenger_scoping
      # </pre>
      #
      # The string index notation strips off the leading whitespace/asterisk
      str[2..-1]
    end
  end

  # @return [true, false] If the repository has been locally cached
  def cached?
    File.exist? @path
  end

  private

  # Reformat the remote name into something that can be used as a directory
  def sanitized_dirname
    @remote.gsub(/[^@\w\.-]/, '-')
  end

  def default_cache_root
    File.expand_path('~/.r10k/git')
  end

  def git_dir
    @path
  end
end
end
end
