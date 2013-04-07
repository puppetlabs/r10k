require 'r10k/logging'
require 'r10k/execution'
require 'r10k/git/command'

module R10K
module Git
class Cache
  # Mirror a git repository for use shared git object repositories
  #
  # @see man git-clone(1)

  include R10K::Logging
  include R10K::Execution
  include R10K::Git::Command

  # @!attribute [r] remote
  #   @return [String] The git repository remote
  attr_reader :remote

  # @!attribute [r] cache_root
  #   @return [String] The directory to use as the cache
  attr_reader :cache_root

  # @!attribute [r] path
  #   @return [String] The path to the git cache repository
  attr_reader :path

  # @param [String] remote
  # @param [String] cache_root
  def initialize(remote, cache_root)
    @remote     = remote
    @cache_root = cache_root

    @path = File.join(cache_root, sanitized_remote_name)
  end

  def sync
    if cached?
      logger.debug "Updating existing cache at #{@path}"
      git "fetch --prune", :git_dir => @cache_path
    else
      logger.debug "No cache for #{@remote.inspect}, forcing cache build"
      cache_root = self.class.cache_root
      FileUtils.mkdir_p cache_root unless File.exist? cache_root
      git "clone --mirror #{@remote} #{@cache_path}"
    end
  end
  alias :cache :sync

  def cached?
    File.exist? @path
  end

  private

  # Reformat the remote name into something that can be used as a directory
  def sanitized_remote_name
    @remote.gsub(/[^@\w\.-]/, '-')
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
end
end
end
