require 'r10k/git'
require 'r10k/git/rugged/working_repository'
require 'r10k/git/rugged/cache'

class R10K::Git::Rugged::ThinRepository < R10K::Git::Rugged::WorkingRepository
  def initialize(basedir, dirname, cache_repo)
    @cache_repo = cache_repo

    super(basedir, dirname)
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
    logger.debug1 { "Cloning '#{remote}' into #{@path}" }
    @cache_repo.sync

    cache_objects_dir = @cache_repo.objects_dir.to_s

    # {Rugged::Repository.clone_at} doesn't support :alternates, which
    # completely breaks how thin repositories need to work. To circumvent
    # this we manually create a Git repository, set up git remotes, and
    # update 'objects/info/alternates' with the path. We don't actually
    # fetch any objects because we don't need them, and we don't actually
    # use any refs in this repository so we skip all those steps.
    ::Rugged::Repository.init_at(@path.to_s, false)
    @_rugged_repo = ::Rugged::Repository.new(@path.to_s, :alternates => [cache_objects_dir])
    alternates << cache_objects_dir

    with_repo do |repo|
      config = repo.config
      config['remote.origin.url']    = remote
      config['remote.origin.fetch']  = '+refs/heads/*:refs/remotes/origin/*'
      config['remote.cache.url']     = @cache_repo.git_dir.to_s
      config['remote.cache.fetch']   = '+refs/heads/*:refs/remotes/cache/*'
    end

    checkout(opts.fetch(:ref, 'HEAD'))
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

  # Override the parent class repo setup so that we can make sure the alternates file is up to date
  # before we create the Rugged::Repository object, which reads from the alternates file.
  def setup_rugged_repo
    entry_added = alternates.add?(@cache_repo.objects_dir.to_s)
    if entry_added
      logger.debug2 { "Updated repo #{@path} to include alternate object db path #{@cache_repo.objects_dir}" }
    end
    super
  end
end
