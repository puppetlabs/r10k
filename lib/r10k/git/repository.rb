require 'r10k/git'
require 'r10k/util/subprocess'

# Define an abstract base class for git repositories.
class R10K::Git::Repository

  # @!attribute [r] remote
  #   @return [String] The URL to the git repository
  attr_reader :remote

  # @!attribute [r] basedir
  #   @return [String] The directory containing the repository
  attr_reader :basedir

  # @!attribute [r] dirname
  #   @return [String] The name of the directory
  attr_reader :dirname

  # @!attribute [r] git_dir
  #   Set the path to the git directory. For git repositories with working copies
  #   this will be `$working_dir/.git`; for bare repositories this will be
  #   `bare-repo.git`
  #   @return [String] The path to the git directory
  attr_reader :git_dir

  # Resolve a ref to a commit hash
  #
  # @param [String] ref
  # @param [String] object_type The object type to look up
  #
  # @return [String] The dereferenced hash of `ref`
  def rev_parse(ref, object_type = 'commit')
    commit = git ['rev-parse', "#{ref}^{#{object_type}}"], :git_dir => git_dir
    commit.chomp
  rescue R10K::Util::Subprocess::SubprocessError
    raise R10K::Git::NonexistentHashError.new(ref, git_dir)
  end

  private

  # Fetch objects and refs from the given git remote
  #
  # @param remote [#to_s] The remote name to fetch from
  def fetch(remote = 'origin')
    git ['fetch', '--prune', remote], :git_dir => @git_dir
  end

  # Wrap git commands
  #
  # @param cmd [Array<String>] cmd The arguments for the git prompt
  # @param opts [Hash] opts
  #
  # @option opts [String] :path
  # @option opts [String] :git_dir
  # @option opts [String] :work_tree
  #
  # @raise [R10K::ExecutionFailure] If the executed command exited with a
  #   nonzero exit code.
  #
  # @return [String] The git command output
  def git(cmd, opts = {})
    argv = %w{git}

    if opts[:path]
      argv << "--git-dir"   << File.join(opts[:path], '.git')
      argv << "--work-tree" << opts[:path]
    else
      if opts[:git_dir]
        argv << "--git-dir" << opts[:git_dir]
      end
      if opts[:work_tree]
        argv << "--work-tree" << opts[:work_tree]
      end
    end

    argv.concat(cmd)

    subproc = R10K::Util::Subprocess.new(argv)
    subproc.raise_on_fail = true

    logger.debug1 "Execute: #{argv.join(' ')}"
    result = subproc.execute

    # todo ensure that logging always occurs even if the command fails to run
    logger.debug2 "[git #{result.cmd}] STDOUT: #{result.stdout.chomp}" unless result.stdout.empty?
    logger.debug2 "[git #{result.cmd}] STDERR: #{result.stderr.chomp}" unless result.stderr.empty?

    result.stdout
  end
end
