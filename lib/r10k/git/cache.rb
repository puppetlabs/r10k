require 'r10k/logging'
require 'r10k/git/repository'

require 'r10k/settings'
require 'r10k/registry'

module R10K
module Git
class Cache < R10K::Git::Repository
  # Mirror a git repository for use shared git object repositories
  #
  # @see man git-clone(1)

  include R10K::Settings::Mixin

  def_setting_attr :cache_root, File.expand_path(ENV['HOME'] ? '~/.r10k/git': '/root/.r10k/git')

  def self.registry
    @registry ||= R10K::Registry.new(self)
  end

  def self.generate(remote)
    registry.generate(remote)
  end

  include R10K::Logging

  # @!attribute [r] remote
  #   @return [String] The git repository remote
  attr_reader :remote

  # @!attribute [r] path
  #   @return [String] The path to the git cache repository
  attr_reader :path

  # @param [String] remote
  # @param [String] cache_root
  def initialize(remote)
    @remote = remote

    @path = File.join(settings[:cache_root], sanitized_dirname)
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

      unless File.exist? settings[:cache_root]
        FileUtils.mkdir_p settings[:cache_root]
      end

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

  def git_dir
    @path
  end
end
end
end
