require 'r10k/git/rugged'
require 'r10k/git/rugged/base_repository'
require 'rugged'

class R10K::Git::Rugged::WorkingRepository < R10K::Git::Rugged::BaseRepository

  #  @return [Pathname] The path to this directory
  attr_reader :path

  # @return [Pathname] The path to the Git repository inside of this directory
  def git_dir
    @path + '.git'
  end

  # @param basedir [String] The base directory of the Git repository
  # @param dirname [String] The directory name of the Git repository
  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))
    if exist? && git_dir.exist?
      @rugged_repo = ::Rugged::Repository.new(@path.to_s, :alternates => alternates.to_a)
    end
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
    @rugged_repo = ::Rugged::Repository.clone_at(remote, @path.to_s, :alternates => opts[:reference])

    if opts[:reference]
      alternates << File.join(opts[:reference], 'objects')
    end

    if opts[:ref]
      checkout(opts[:ref])
    end
  end

  # Check out the given Git ref
  #
  # @param ref [String] The git reference to check out
  # @return [void]
  def checkout(ref)
    sha = resolve(ref)
    @rugged_repo.checkout(sha)
    @rugged_repo.reset(sha, :hard)
  end

  def fetch(remote = 'origin')
    refspecs = ["+refs/heads/*:refs/remotes/#{remote}/*"]
    @rugged_repo.fetch(remote, refspecs)
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
    if @rugged_repo
      @rugged_repo.config['remote.origin.url']
    end
  end
end
