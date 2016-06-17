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

  extend Forwardable
  def_delegators :@repo, :head

  # Create a new shallow git working directory
  #
  # @param ref     [String] The git ref to check out
  # @param remote  [String] The git remote to use for the repo
  # @param basedir [String] The path containing the Git repo
  # @param dirname [String] The directory name of the Git repo
  def initialize(ref, remote, basedir, dirname)
    @ref = ref
    @remote = remote

    @cache = R10K::Git.cache.generate(remote)
    @repo = R10K::Git.thin_repository.new(basedir, dirname, @cache)
  end

  def sync
    @cache.sync if sync_cache?

    sha = @cache.resolve(@ref)

    if sha.nil?
      raise R10K::Git::UnresolvableRefError.new("Unable to sync repo to unresolvable ref '#{@ref}'", :git_dir => @repo.git_dir)
    end

    case status
    when :absent
      logger.debug { "Cloning #{@repo.path} and checking out #{@ref}" }
      @repo.clone(@remote, {:ref => sha})
    when :mismatched
      logger.debug { "Replacing #{@repo.path} and checking out #{@ref}" }
      @repo.path.rmtree
      @repo.clone(@remote, {:ref => sha})
    when :outdated
      logger.debug { "Updating #{@repo.path} to #{@ref}" }
      @repo.checkout(sha)
    else
      logger.debug { "#{@repo.path} is already at Git ref #{@ref}" }
    end
  end

  def status
    if !@repo.exist?
      :absent
    elsif !@repo.git_dir.exist?
      :mismatched
    elsif !@repo.git_dir.directory?
      :mismatched
    elsif !(@repo.origin == @remote)
      :mismatched
    elsif !(@repo.head == @cache.resolve(@ref))
      :outdated
    elsif @cache.ref_type(@ref) == :branch && !@cache.synced?
      :outdated
    elsif @repo.changes > 0
      logger.debug { "Found #{@repo.changes} changes unstaged in workdir" }
      :mismatched
    else
      :insync
    end
  end

  # @api private
  def sync_cache?
    return true if !@cache.exist?
    return true if !@cache.resolve(@ref)
    return true if !([:commit, :tag].include? @cache.ref_type(@ref))
    return false
  end
end
