require 'r10k/execution'
require 'r10k/git/errors'

module R10K
module Git
class Repository
  # Define an abstract base class for git repositories.

  include R10K::Execution

  # @!attribute [r] remote
  #   @return [String] The URL to the git repository
  attr_reader :remote

  # @!attribute [r] basedir
  #   @return [String] The basedir for the working directory
  attr_reader :basedir

  # @!attribute [r] dirname
  #   @return [String] The name for the directory
  attr_reader :dirname

  # Resolve a ref to a commit hash
  #
  # @param [String] ref
  #
  # @return [String] The dereferenced hash of `ref`
  def rev_parse(ref)
    commit = git "rev-parse #{ref}^{commit}", :git_dir => git_dir
    commit.chomp
  rescue R10K::ExecutionFailure
    raise R10K::Git::NonexistentHashError.new(ref, git_dir)
  end

  # Wrap git commands
  #
  # @param [String] command_line_args The arguments for the git prompt
  # @param [Hash] opts
  #
  # @option opts [String] :git_dir
  # @option opts [String] :work_tree
  # @option opts [String] :work_tree
  #
  # @raise [R10K::ExecutionFailure] If the executed command exited with a
  #   nonzero exit code.
  #
  # @return [String] The git command output
  def git(command_line_args, opts = {})
    args = %w{git}

    log_event = "git #{command_line_args}"
    log_event << ", args: #{opts.inspect}" unless opts.empty?


    if opts[:path]
      args << "--git-dir #{opts[:path]}/.git"
      args << "--work-tree #{opts[:path]}"
    else
      if opts[:git_dir]
        args << "--git-dir #{opts[:git_dir]}"
      end
      if opts[:work_tree]
        args << "--work-tree #{opts[:work_tree]}"
      end
    end

    args << command_line_args
    cmd = args.join(' ')

    execute(cmd, :event => log_event)
  end
end
end
end
