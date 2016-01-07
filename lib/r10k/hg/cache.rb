require 'r10k/hg/bare_repository'

require 'r10k/settings'
require 'r10k/instance_cache'
require 'forwardable'

# Cache Mercurial repository mirrors.
#
# @abstract
class R10K::Hg::Cache

  include R10K::Settings::Mixin

  def_setting_attr :cache_root, File.expand_path(ENV['HOME'] ? '~/.r10k/hg': '/root/.r10k/hg')

  @instance_cache = R10K::InstanceCache.new(self)

  # @api private
  def self.instance_cache
    @instance_cache
  end

  # Generate a new instance with the given remote or return an existing object
  # with the given remote. This should be used over R10K::Hg::Cache.new.
  #
  # @api public
  # @param remote [String] The Mercurial remote repository to cache
  # @return [R10K::Hg::Cache] The requested cache object.
  def self.generate(remote)
    instance_cache.generate(remote)
  end

  # @abstract
  # @return [Object] The concrete bare repository implementation to use for
  #   interacting with the cached Mercurial repository.
  def self.bare_repository
    R10K::Hg::BareRepository
  end

  include R10K::Logging

  extend Forwardable

  def_delegators :@repo, :hg_dir, :objects_dir, :branches, :tags, :exist?, :resolve, :ref_type

  # @!attribute [r] path
  #   @deprecated
  #   @return [String] The path to the Mercurial cache repository
  def path
    logger.warn "#{self.class}#path is deprecated; use #hg_dir"
    hg_dir
  end

  # @!attribute [r] repo
  #   @api private
  attr_reader :repo

  # @param remote [String] The URL of the Mercurial remote URL to cache.
  def initialize(remote)
    @remote = remote
    @repo = self.class.bare_repository.new(settings[:cache_root], sanitized_dirname)
  end

  def sync
    if !@synced
      sync!
      @synced = true
    end
  end

  def synced?
    @synced
  end

  def sync!
    if cached?
      @repo.fetch
    else
      logger.debug1 "Creating new Mercurial cache for #{@remote.inspect}"

      # TODO extract this to an initialization step
      if !File.exist?(settings[:cache_root])
        FileUtils.mkdir_p settings[:cache_root]
      end

      @repo.clone(@remote)
    end
  end

  # @api private
  def reset!
    @synced = false
  end

  alias cached? exist?

  private

  # Reformat the remote name into something that can be used as a directory
  def sanitized_dirname
    @remote.gsub(/[^@\w\.-]/, '-')
  end
end
