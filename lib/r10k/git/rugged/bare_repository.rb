require 'r10k/git/rugged'
require 'r10k/git/rugged/base_repository'

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

  # Clone the given remote.
  #
  # This should only be called if the repository does not exist.
  #
  # @param remote [String] The URL of the Git remote to clone.
  # @return [void]
  def clone(remote)
    @_rugged_repo = ::Rugged::Repository.init_at(@path.to_s, true)
    with_repo do |repo|
      config = repo.config
      config['remote.origin.url']    = remote
      config['remote.origin.fetch']  = '+refs/*:refs/*'
      config['remote.origin.mirror'] = 'true'
      fetch
    end
  end

  # Fetch refs and objects from the origin remote
  #
  # @return [void]
  def fetch
    options = {:credentials => credentials}
    refspecs = ['+refs/*:refs/*']
    with_repo { |repo| repo.fetch('origin', refspecs, options) }
  end

  def exist?
    @path.exist?
  end
end
