require 'r10k/git'
require 'r10k/git/working_repository'

# Manage a Git working repository backed with cached bare repositories. Instead
# of duplicating all objects for new clones and updates, this uses Git
# alternate object databases to reuse objects from an existing repository,
# making new clones very lightweight.
class R10K::Git::ThinRepository < R10K::Git::WorkingRepository

  def initialize(basedir, dirname)
    super

    if exist? && origin
      set_cache(origin)
    end
  end

  # Clone this git repository
  #
  # @param remote [String] The Git remote to clone
  # @param opts [Hash]
  #
  # @options opts [String] :ref The git ref to check out on clone
  #
  # @return [void]
  def clone(remote, opts = {})
    # todo check if opts[:reference] is set
    set_cache(remote)
    @cache_repo.sync

    super(remote, opts.merge(:reference => @cache_repo.git_dir))
    setup_cache_remote
  end

  # Fetch refs from the backing bare Git repository.
  def fetch(remote = 'cache')
    git ['fetch', remote], :path => @path.to_s
  end

  # @return [String] The origin remote URL
  def cache
    git(['config', '--get', 'remote.cache.url'], :path => @path.to_s, :raise_on_fail => false).stdout
  end

  private

  def set_cache(remote)
    @cache_repo = R10K::Git::Cache.generate(remote)
  end

  def setup_cache_remote
    git ["remote", "add", "cache", @cache_repo.git_dir], :path => @path.to_s
    fetch
  end
end
