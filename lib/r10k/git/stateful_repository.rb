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
  attr_accessor :expect_dirty

  extend Forwardable
  def_delegators :@repo, :head, :tracked_paths

  # Create a new shallow git working directory
  #
  # @param remote  [String] The git remote to use for the repo
  # @param basedir [String] The path containing the Git repo
  # @param dirname [String] The directory name of the Git repo
  def initialize(remote, basedir, dirname, gitdirname = '.git')
    @remote = remote
    @cache = R10K::Git.cache.generate(@remote)
    @repo = R10K::Git.thin_repository.new(basedir, dirname, gitdirname, @cache)
  end

  def resolve(ref)
    @cache.sync if sync_cache?(ref)
    @cache.resolve(ref)
  end

  def sync(ref, force=true)
    @cache.sync if sync_cache?(ref)

    sha = @cache.resolve(ref)

    if sha.nil?
      raise R10K::Git::UnresolvableRefError.new(_("Unable to sync repo to unresolvable ref '%{ref}'") % {ref: ref}, :git_dir => @repo.git_dir)
    end

    workdir_status = status(ref)

    case workdir_status
    when :absent, :uninitialized
      logger.debug(_("Cloning %{repo_path} and checking out %{ref}") % {repo_path: @repo.path, ref: ref })
      @repo.clone(@remote, {:ref => sha})
    when :mismatched
      logger.debug(_("Replacing %{repo_path} and checking out %{ref}") % {repo_path: @repo.path, ref: ref })
      @repo.git_dir.rmtree
      @repo.clone(@remote, {:ref => sha})
    when :outdated
      logger.debug(_("Updating %{repo_path} to %{ref}") % {repo_path: @repo.path, ref: ref })
      @repo.checkout(sha, {:force => force})
    when :dirty
      if (!force && !expect_dirty)
        logger.warn(_("Skipping %{repo_path} due to local modifications") % {repo_path: @repo.path})
      elsif (force && !expect_dirty)
        logger.warn(_("Overwriting local modifications to %{repo_path}") % {repo_path: @repo.path})
      end

      if (force || expect_dirty)
        logger.debug(_("Updating %{repo_path} to %{ref}") % {repo_path: @repo.path, ref: ref })
        @repo.checkout(sha, {:force => true})
      end
    else
      logger.debug(_("%{repo_path} is already at Git ref %{ref}") % {repo_path: @repo.path, ref: ref })
    end
  end

  def status(ref)
    if !@repo.exist?
      :absent
    elsif !@repo.git_dir.exist?
      :uninitialized
    elsif !@repo.git_dir.directory?
      :mismatched
    elsif !(@repo.origin == @remote)
      :mismatched
    elsif @repo.dirty?
      :dirty
    elsif !(@repo.head == @cache.resolve(ref))
      :outdated
    elsif @cache.ref_type(ref) == :branch && !@cache.synced?
      :outdated
    else
      :insync
    end
  end

  # @api private
  def sync_cache?(ref)
    return true if !@cache.exist?
    return true if !([:commit, :tag].include? @cache.ref_type(ref))
    return false
  end
end
