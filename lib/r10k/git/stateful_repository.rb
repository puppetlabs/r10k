require 'r10k/git'
require 'r10k/git/errors'
require 'forwardable'

# Manage how Git repositories are created and set to specific refs
class R10K::Git::StatefulRepository

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

    @repo = R10K::Git.thin_repository.new(basedir, dirname)
    @cache = R10K::Git.cache.generate(remote)
  end

  def sync
    @cache.sync if sync?

    sha = @cache.resolve(@ref)

    if sha.nil?
      raise R10K::Git::UnresolvableRefError.new("Unable to sync repo to unresolvable ref '#{@ref}'", :git_dir => @repo.git_dir)
    end

    case status
    when :absent
      @repo.clone(@remote, {:ref => sha})
    when :mismatched
      @repo.path.rmtree
      @repo.clone(@remote, {:ref => sha})
    when :outdated
      @repo.checkout(sha)
    end
  end

  def status
    if !@repo.exist?
      :absent
    elsif !@repo.git_dir.exist?
      :mismatched
    elsif !(@repo.origin == @remote)
      :mismatched
    elsif !(@repo.head == @cache.resolve(@ref))
      :outdated
    elsif @cache.ref_type(@ref) == :branch && !@cache.synced?
      :outdated
    else
      :insync
    end
  end

  private

  def sync?
    return true if !@cache.exist?
    return true if !(sha = @cache.resolve(@ref))
    return true if !([:commit, :tag].include? @cache.ref_type(sha))
    return false
  end
end
