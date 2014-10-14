require 'forwardable'
require 'r10k/git'
require 'r10k/git/cache'

# Implements sparse git repositories with shared objects
#
# Working directory instances use the git alternatives object store, so that
# working directories only contain checked out files and all object files are
# shared.
class R10K::Git::WorkingDir < R10K::Git::Repository

  include R10K::Logging

  extend Forwardable

  # @!attribute [r] cache
  #   @return [R10K::Git::Cache] The object cache backing this working directory
  attr_reader :cache

  # @!attribute [r] ref
  #   @return [R10K::Git::Ref] The git reference to use check out in the given directory
  attr_reader :ref

  # @!attribute [r] remote
  #   @return [String] The actual remote used as an upstream for this module.
  attr_reader :remote

  # Create a new shallow git working directory
  #
  # @param ref     [String, R10K::Git::Ref]
  # @param remote  [String]
  # @param basedir [String]
  # @param dirname [String]
  def initialize(ref, remote, basedir, dirname = nil)

    @remote  = remote
    @basedir = basedir
    @dirname = dirname || ref

    @full_path = File.join(@basedir, @dirname)
    @git_dir   = File.join(@full_path, '.git')

    @alternates = R10K::Git::Alternates.new(@git_dir)
    @cache      = R10K::Git::Cache.generate(@remote)

    if ref.is_a? String
      @ref = R10K::Git::Ref.new(ref, self)
    else
      @ref = ref
      @ref.repository = self
    end
  end

  # Synchronize the local git repository.
  def sync
    if not cloned?
      clone
    else
      update
    end
  end

  def update
    update_remotes if update_remotes?

    if ref_needs_fetch?
      fetch_from_cache
      checkout(@ref)
    elsif needs_checkout?
      checkout(@ref)
    end
  end

  # Determine if repo has been cloned into a specific dir
  #
  # @return [true, false] If the repo has already been cloned
  def cloned?
    File.directory? @git_dir
  end
  alias :git? :cloned?

  # Does a directory exist where we expect a working dir to be?
  # @return [true, false]
  def exist?
    File.directory? @full_path
  end

  # check out the given ref
  #
  # @param ref [R10K::Git::Ref] The git reference to check out
  def checkout(ref)
    if ref.resolvable?
      git ["checkout", "--force", @ref.sha1], :path => @full_path
    else
      raise R10K::Git::UnresolvableRefError.new(
        "Cannot check out unresolvable ref '#{@ref}'",
        :git_dir => @full_path)
    end
  end

  # The currently checked out HEAD
  #
  # @return [R10k::Git::Head]
  def current
    R10K::Git::Head.new('HEAD', self)
  end

  def outdated?
    fetch_from_cache
    needs_checkout?
  end

  # Prefer remote heads from the 'cache' remote over the real remote
  def resolve_remote_head(pattern, remote = 'cache')
    super(pattern, remote)
  end

  private

  # Do we need to fetch additional objects and refs in order to resolve the given ref?
  # @return [true, false]
  def ref_needs_fetch?
    @ref.fetch?
  end

  def fetch_from_cache
    @cache.sync
    fetch('cache')
  end

  # Perform a non-bare clone of a git repository.
  def clone
    @cache.sync

    # We do the clone against the target repo using the `--reference` flag so
    # that doing a normal `git pull` on a directory will work.
    git ["clone", "--reference", @cache.git_dir, @remote, @full_path]
    git ["remote", "add", "cache", @cache.git_dir], :path => @full_path
    git ['fetch', 'cache'], :path => @full_path
    checkout(@ref)
  end

  def needs_fetch?
    ref.fetch?
  end

  # Does the expected ref match the actual ref?
  def needs_checkout?
    expected = ref.sha1
    actual   = rev_parse('HEAD')

    !(expected == actual)
  end

  def update_remotes?
    real_remotes = remotes

    expected_origin = @remote
    expected_cache  = @cache.git_dir

    !(expected_origin == real_remotes['origin'] and expected_cache == real_remotes['cache'])
  end

  def update_remotes
    # todo: remove all existing refs as they may belong to the old remote
    git ['remote', 'set-url', 'origin', remote], :path => @full_path
    git ['remote', 'set-url', 'cache', @cache.git_dir], :path => @full_path
    @alternates << File.join(@cache.git_dir, 'objects')
    logger.debug("Removing stale git tags from #{@full_path}")
    remove_tags
  end

  def remove_tags
    tags.each do |tag|
      git ['tag', '-d', tag], :path => @full_path
    end
  end
end
