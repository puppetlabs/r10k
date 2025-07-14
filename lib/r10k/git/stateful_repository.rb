require 'r10k/git'
require 'r10k/git/errors'
require 'forwardable'
require 'r10k/logging'

# Manage how Git repositories are created and set to specific refs
class R10K::Git::StatefulRepository

  include R10K::Logging

  # @!attribute [r] repo
  #   @api private
  attr_reader :repo

  # @!attribute [r] cache
  #   @api private
  attr_reader :cache

  extend Forwardable
  def_delegators :@repo, :head, :tracked_paths

  # Create a new shallow git working directory
  #
  # @param remote  [String] The git remote to use for the repo
  # @param basedir [String] The path containing the Git repo
  # @param dirname [String] The directory name of the Git repo
  def initialize(remote, basedir, dirname)
    @remote = remote
    @cache = R10K::Git.cache.generate(@remote)
    @repo = R10K::Git.thin_repository.new(basedir, dirname, @cache)
  end

  def resolve(ref)
    @cache.sync if sync_cache?(ref)
    @cache.resolve(ref)
  end

  # Returns true if the sync actually updated the repo, false otherwise
  def sync(ref, force=true, exclude_spec=true)
    @cache.sync if sync_cache?(ref)

    sha = @cache.resolve(ref)

    if sha.nil?
      raise R10K::Git::UnresolvableRefError.new(_("Unable to sync repo to unresolvable ref '%{ref}'") % {ref: ref}, :git_dir => @repo.git_dir)
    end

    workdir_status = status(ref, exclude_spec)

    updated = true
    case workdir_status
    when :absent
      logger.debug(_("Cloning %{repo_path} and checking out %{ref}") % {repo_path: @repo.path, ref: ref })
      @repo.clone(@remote, {:ref => sha})
    when :mismatched
      logger.debug(_("Replacing %{repo_path} and checking out %{ref}") % {repo_path: @repo.path, ref: ref })
      @repo.path.rmtree
      @repo.clone(@remote, {:ref => sha})
    when :outdated
      logger.debug(_("Updating %{repo_path} to %{ref}") % {repo_path: @repo.path, ref: ref })
      @repo.checkout(sha, {:force => force})
    when :dirty
      if force
        logger.warn(_("Overwriting local modifications to %{repo_path}") % {repo_path: @repo.path})
        logger.debug(_("Updating %{repo_path} to %{ref}") % {repo_path: @repo.path, ref: ref })
        @repo.prune
        @repo.fetch
        @repo.checkout(sha, {:force => force})
      else
        logger.warn(_("Skipping %{repo_path} due to local modifications") % {repo_path: @repo.path})
        updated = false
      end
    when :updatedtags
      logger.debug(_("Updating tags in %{repo_path}") % {repo_path: @repo.path})
      @repo.fetch
    else
      logger.debug(_("%{repo_path} is already at Git ref %{ref}") % {repo_path: @repo.path, ref: ref })
      updated = false
    end
    updated
  end

  def status(ref, exclude_spec=true)
    if !@repo.exist?
      :absent
    elsif !@cache.exist?
      :mismatched
    elsif !@repo.git_dir.exist?
      :mismatched
    elsif !@repo.git_dir.directory?
      :mismatched
    elsif !(@repo.origin == @remote)
      :mismatched
    elsif @repo.head.nil?
      :mismatched
    elsif @repo.dirty?(exclude_spec)
      :dirty
    elsif !(@repo.head == @cache.resolve(ref))
      :outdated
    elsif @cache.ref_type(ref) == :branch && !@cache.synced?
      :outdated
    elsif @repo.updatedtags?
      :updatedtags
    else
      :insync
    end
  end

  # @api private
  def sync_cache?(ref)
    return true if !@cache.exist?
    return true if ref == 'HEAD'
    return true if !([:commit, :tag].include? @cache.ref_type(ref))
    return false
  end
end
