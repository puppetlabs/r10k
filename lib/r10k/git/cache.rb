require 'r10k/git'
require 'r10k/git/repository'
require 'r10k/git/bare_repository'

require 'r10k/settings'
require 'r10k/instance_cache'
require 'forwardable'

# Cache Git repository mirrors for object database reuse.
#
# @see man git-clone(1)
class R10K::Git::Cache

  include R10K::Settings::Mixin

  def_setting_attr :cache_root, File.expand_path(ENV['HOME'] ? '~/.r10k/git': '/root/.r10k/git')

  # Lazily construct an instance cache for R10K::Git::Cache objects
  # @api private
  def self.instance_cache
    @instance_cache ||= R10K::InstanceCache.new(self)
  end

  # Generate a new instance with the given remote or return an existing object
  # with the given remote. This should be used over R10K::Git::Cache.new.
  #
  # @api public
  # @param remote [String] The git remote to cache
  # @return [R10K::Git::Cache] The requested cache object.
  def self.generate(remote)
    instance_cache.generate(remote)
  end

  include R10K::Logging

  extend Forwardable

  def_delegators :@repo, :git_dir, :branches, :tags, :exist?

  # @!attribute [r] path
  #   @deprecated
  #   @return [String] The path to the git cache repository
  def path
    logger.warn "#{self.class}#path is deprecated; use #git_dir"
    git_dir
  end

  # @!attribute [r] repo
  #   @api private
  attr_reader :repo

  # @param [String] remote
  # @param [String] cache_root
  def initialize(remote)
    @remote = remote
    @repo = R10K::Git::BareRepository.new(settings[:cache_root], sanitized_dirname)
  end

  def sync
    if !@synced
      sync!
      @synced = true
    end
  end

  def sync!
    if cached?
      @repo.fetch
    else
      logger.debug "Creating new git cache for #{@remote.inspect}"

      # TODO extract this to an initialization step
      if !File.exist?(settings[:cache_root])
        FileUtils.mkdir_p settings[:cache_root]
      end

      @repo.clone(@remote)
    end
  end

  alias cached? exist?

  private

  # Reformat the remote name into something that can be used as a directory
  def sanitized_dirname
    @remote.gsub(/[^@\w\.-]/, '-')
  end
end
