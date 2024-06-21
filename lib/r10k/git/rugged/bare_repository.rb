require 'r10k/git/rugged'
require 'r10k/git/rugged/base_repository'
require 'r10k/git/errors'

class R10K::Git::Rugged::BareRepository < R10K::Git::Rugged::BaseRepository

  # @param basedir [String] The base directory of the Git repository
  # @param dirname [String] The directory name of the Git repository
  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))

    if exist?
      @_rugged_repo = ::Rugged::Repository.bare(@path.to_s)
    end
  end

  # @return [Pathname] The path to this Git repository
  def git_dir
    @path
  end

  # @return [Pathname] The path to the objects directory in this Git repository
  def objects_dir
    @path + "objects"
  end

  # Clone the given remote.
  #
  # This should only be called if the repository does not exist.
  #
  # @param remote [String] The URL of the Git remote to clone.
  # @return [void]
  def clone(remote)
    logger.debug1 { _("Cloning '%{remote}' into %{path}") % {remote: remote, path: @path} }

    @_rugged_repo = ::Rugged::Repository.init_at(@path.to_s, true).tap do |repo|
      config = repo.config
      config['remote.origin.url']    = remote
      config['remote.origin.fetch']  = '+refs/heads/*:refs/heads/*'
      config['remote.origin.mirror'] = 'true'
    end

    fetch('origin')
  rescue Rugged::SshError, Rugged::NetworkError => e
    raise R10K::Git::GitError.new(e.message, :git_dir => git_dir, :backtrace => e.backtrace)
  end

  # Fetch refs and objects from the origin remote
  #
  # @return [void]
  def fetch(remote_name='origin')
    logger.debug1 { _("Fetching remote '%{remote_name}' at %{path}") % {remote_name: remote_name, path: @path } }

    # Check to see if we have a version of Rugged that supports "fetch --prune" and warn if not
    if defined?(Rugged::Version) && !Gem::Dependency.new('rugged', '>= 0.24.0').match?('rugged', Rugged::Version)
      logger.warn { _("Rugged versions prior to 0.24.0 do not support pruning stale branches during fetch, please upgrade your \'rugged\' gem. (Current version is: %{version})") % {version: Rugged::Version} }
    end

    remote = remotes[remote_name]
    proxy = R10K::Git.get_proxy_for_remote(remote)

    options = {:credentials => credentials, :prune => true, :proxy_url => proxy}
    refspecs = ['+refs/heads/*:refs/heads/*']

    results = nil

    R10K::Git.with_proxy(proxy) do
      results = with_repo { |repo| repo.fetch(remote_name, refspecs, **options) }
    end

    report_transfer(results, remote_name)
  rescue Rugged::SshError, Rugged::NetworkError => e
    if e.message =~ /Unsupported proxy scheme for/
      message = e.message + "As of curl ver 7.50.2, unsupported proxy schemes no longer fall back to HTTP."
    else
      message = e.message
    end
    raise R10K::Git::GitError.new(message, :git_dir => git_dir, :backtrace => e.backtrace)
  rescue
    raise
  end

  def exist?
    @path.exist?
  end
end
