require 'r10k/git'

require 'r10k/settings'
require 'r10k/instance_cache'
require 'forwardable'

# Cache Git repository mirrors for object database reuse.
#
# This implements most of the behavior needed for Git repo caching, but needs
# to have a specific Git bare repository provided. Subclasses should implement
# the {bare_repository} method.
#
# @abstract
# @see man git-clone(1)
class R10K::Git::Cache

  include R10K::Settings::Mixin

  def_setting_attr :cache_root, File.expand_path(ENV['HOME'] ? '~/.r10k/git': '/root/.r10k/git')

  @instance_cache = R10K::InstanceCache.new(self)

  # @api private
  def self.instance_cache
    @instance_cache
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

  # @abstract
  # @return [Object] The concrete bare repository implementation to use for
  #   interacting with the cached Git repository.
  def self.bare_repository
    raise NotImplementedError
  end

  include R10K::Logging

  extend Forwardable

  def_delegators :@repo, :git_dir, :objects_dir, :branches, :tags, :exist?, :resolve, :ref_type

  # @!attribute [r] path
  #   @deprecated
  #   @return [String] The path to the git cache repository
  def path
    logger.warn _("%{class}#path is deprecated; use #git_dir") % {class: self.class}
    git_dir
  end

  # @!attribute [r] repo
  #   @api private
  attr_reader :repo

  # @param remote [String] The URL of the Git remote URL to cache.
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
      logger.debug1 _("Creating new git cache for %{remote}") % {remote: @remote.inspect}

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

  # Reformat the remote name into something that can be used as a directory
  def sanitized_dirname
    @sanitized_dirname ||= @remote.gsub(/[^@\w\.-]/, '-')
  end
end
