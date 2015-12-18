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
    logger.debug1 { "Cloning '#{remote}' into #{@path}" }
    @_rugged_repo = ::Rugged::Repository.init_at(@path.to_s, true)
    with_repo do |repo|
      config = repo.config
      config['remote.origin.url']    = remote
      config['remote.origin.fetch']  = '+refs/*:refs/*'
      config['remote.origin.mirror'] = 'true'
      fetch
    end
  rescue Rugged::SshError, Rugged::NetworkError => e
    raise R10K::Git::GitError.new(e.message, :git_dir => git_dir, :backtrace => e.backtrace)
  end

  # Fetch refs and objects from the origin remote
  #
  # @return [void]
  def fetch
    backup_branches = wipe_branches
    logger.debug1 { "Fetching remote 'origin' at #{@path}" }
    options = {:credentials => credentials}
    refspecs = ['+refs/*:refs/*']
    results = with_repo { |repo| repo.fetch('origin', refspecs, options) }
    report_transfer(results, 'origin')
  rescue Rugged::SshError, Rugged::NetworkError => e
    restore_branches(backup_branches)
    raise R10K::Git::GitError.new(e.message, :git_dir => git_dir, :backtrace => e.backtrace)
  rescue
    restore_branches(backup_branches)
    raise
  end

  def exist?
    @path.exist?
  end

  def wipe_branches
    backup_branches = {}
    with_repo do |repo|
      repo.branches.each do |branch|
        if !branch.head?
          backup_branches[branch.name] = branch.target_id
          repo.branches.delete(branch)
        end
      end
    end
    backup_branches
  end

  def restore_branches(backup_branches)
    with_repo do |repo|
      backup_branches.each_pair do |name, ref|
        if !repo.branches.exist?(name)
          repo.create_branch(name, ref)
        end
      end
    end
  end

  def blob_at(treeish, path)
    blob = nil

    with_repo do |repo|
      object = repo.rev_parse(treeish)

      # Resolve tag annotations to the underlying commit.
      sha = object.respond_to?(:target_oid) ? object.target_oid : object.oid

      blob = repo.blob_at(sha, path)
    end

    blob.content.strip
  end
end
