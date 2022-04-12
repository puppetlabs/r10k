require 'r10k/git/rugged'
require 'r10k/git/rugged/base_repository'
require 'r10k/git/errors'

class R10K::Git::Rugged::WorkingRepository < R10K::Git::Rugged::BaseRepository

  # @return [Pathname] The path to the Git repository inside of this directory
  def git_dir
    @path + '.git'
  end

  # @param basedir [String] The base directory of the Git repository
  # @param dirname [String] The directory name of the Git repository
  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))
  end

  # Clone this git repository
  #
  # @param remote [String] The Git remote to clone
  # @param opts [Hash]
  #
  # @options opts [String] :ref The git ref to check out on clone
  # @options opts [String] :reference A Git repository to use as an alternate object database
  #
  # @return [void]
  def clone(remote, opts = {})
    logger.debug1 { _("Cloning '%{remote}' into %{path}") % {remote: remote, path: @path } }

    # libgit2/rugged doesn't support cloning a repository and providing an
    # alternate object database, making the handling of :alternates a noop.
    # Unfortunately this means that this method can't really use alternates
    # and running the clone will duplicate all objects in the specified
    # repository. However alternate databases can be handled when an existing
    # repository is loaded, so loading a cloned repo will correctly use
    # alternate object database.
    options = {:credentials => credentials}
    options.merge!(:alternates => [File.join(opts[:reference], 'objects')]) if opts[:reference]

    proxy = R10K::Git.get_proxy_for_remote(remote)

    R10K::Git.with_proxy(proxy) do
      @_rugged_repo = ::Rugged::Repository.clone_at(remote, @path.to_s, options)
    end

    if opts[:reference]
      alternates << File.join(opts[:reference], 'objects')
    end

    if opts[:ref]
      # todo:  always check out something; since we're fetching a repository we
      # won't populate the working directory.
      checkout(opts[:ref])
    end
  rescue Rugged::SshError, Rugged::NetworkError => e
    raise R10K::Git::GitError.new(e.message, :git_dir => git_dir, :backtrace => e.backtrace)
  end

  # Check out the given Git ref
  #
  # @param ref [String] The git reference to check out
  # @return [void]
  def checkout(ref, opts = {})
    sha = resolve(ref)

    if sha
      logger.debug2 { _("Checking out ref '%{ref}' (resolved to SHA '%{sha}') in repository %{path}") % {ref: ref, sha: sha, path: @path} }
    else
      raise R10K::Git::GitError.new("Unable to check out unresolvable ref '#{ref}'", git_dir: git_dir)
    end

    # :force defaults to true
    force = !opts.has_key?(:force) || opts[:force]

    with_repo do |repo|
      # rugged/libgit2 will not update (at least) the execute bit a file if the SHA is already at
      # the value being reset to, so this is now changed to an if ... else
      if force
        repo.reset(sha, :hard)
      else
        repo.checkout(sha)
      end
    end
  end

  def fetch(remote_name = 'origin')
    logger.debug1 { _("Fetching remote '%{remote}' at %{path}") % {remote: remote_name, path: @path} }
    options = {:credentials => credentials}
    refspecs = ["+refs/heads/*:refs/remotes/#{remote_name}/*"]

    remote = remotes[remote_name]
    proxy = R10K::Git.get_proxy_for_remote(remote)
    results = nil

    R10K::Git.with_proxy(proxy) do
      results = with_repo { |repo| repo.fetch(remote_name, refspecs, **options) }
    end

    report_transfer(results, remote)
  rescue Rugged::SshError, Rugged::NetworkError => e
    raise R10K::Git::GitError.new(e.message, :git_dir => git_dir, :backtrace => e.backtrace)
  end

  def exist?
    @path.exist?
  end

  def head
    resolve('HEAD')
  end

  def alternates
    R10K::Git::Alternates.new(git_dir)
  end

  def origin
    with_repo { |repo| repo.config['remote.origin.url'] }
  end

  def dirty?(exclude_spec=false)
    with_repo do |repo|
      if exclude_spec
        diff = repo.diff_workdir('HEAD').filter { |d| ! d.delta.old_file[:path].start_with?('spec/') }
      else
        diff = repo.diff_workdir('HEAD').to_a
      end

      diff.each do |p|
        logger.debug(_("Found local modifications in %{file_path}" % {file_path: File.join(@path, p.delta.old_file[:path])}))
        logger.debug1(p.to_s)
      end

      return diff.size > 0
    end
  end

  private

  def with_repo
    if @_rugged_repo.nil? && git_dir.exist?
      setup_rugged_repo
    end
    super
  end

  def setup_rugged_repo
    @_rugged_repo = ::Rugged::Repository.new(@path.to_s, :alternates => alternates.to_a)
  end
end
