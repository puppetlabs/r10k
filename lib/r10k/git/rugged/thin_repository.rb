require 'r10k/git'
require 'r10k/git/rugged/working_repository'
require 'r10k/git/rugged/cache'

class R10K::Git::Rugged::ThinRepository < R10K::Git::Rugged::WorkingRepository
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
    set_cache(remote)
    @cache_repo.sync

    objectpath = (@cache_repo.git_dir + 'objects').to_s

    ::Rugged::Repository.init_at(@path.to_s, false)
    @_rugged_repo = ::Rugged::Repository.new(@path.to_s, :alternates => [objectpath])
    alternates << objectpath

    with_repo do |repo|
      config = repo.config
      config['remote.origin.url']    = remote
      config['remote.origin.fetch']  = '+refs/heads/*:refs/remotes/origin/*'
      config['remote.cache.url']     = @cache_repo.git_dir.to_s
      config['remote.cache.fetch']   = '+refs/heads/*:refs/remotes/cache/*'
    end

    if opts[:ref]
      checkout(opts[:ref])
    end
  end

  def checkout(ref)
    super(@cache_repo.resolve(ref))
  end

  # Fetch refs and objects from one of the Git remotes
  #
  # @param remote [String] The remote to fetch, defaults to 'cache'
  # @return [void]
  def fetch(remote = 'cache')
    super(remote)
  end

  # @return [String] The cache remote URL
  def cache
    with_repo { |repo| repo.config['remote.cache.url'] }
  end

  private

  def set_cache(remote)
    @cache_repo = R10K::Git::Rugged::Cache.generate(remote)
  end
end
