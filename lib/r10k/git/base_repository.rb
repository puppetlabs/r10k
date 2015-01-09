require 'r10k/git'
require 'r10k/logging'

class R10K::Git::BaseRepository

  # @abstract
  # @return [Pathname] The path to the Git directory
  def git_dir
    raise NotImplementedError
  end

  # Resolve the given Git ref to a commit
  #
  # @param pattern [String] The git ref to resolve
  # @return [String, nil] The commit SHA if the ref could be resolved, nil otherwise.
  def resolve(pattern)
    result = git ['rev-parse', "#{pattern}^{commit}"], :git_dir => git_dir.to_s, :raise_on_fail => false
    if result.success?
      result.stdout
    end
  end

  # For compatibility with R10K::Git::Ref
  # @todo remove alias
  alias rev_parse resolve

  # @return [Array<String>] All tags in this repository
  def tags
    output = git %w[for-each-ref refs/tags --format %(refname)], :git_dir => git_dir.to_s
    output.stdout.scan(%r[refs/tags/(.*)$]).flatten
  end

  include R10K::Logging

  private

  # Wrap git commands
  #
  # @param cmd [Array<String>] cmd The arguments for the git prompt
  # @param opts [Hash] opts
  #
  # @option opts [String] :path
  # @option opts [String] :git_dir
  # @option opts [String] :work_tree
  # @option opts [String] :raise_on_fail
  #
  # @raise [R10K::ExecutionFailure] If the executed command exited with a
  #   nonzero exit code.
  #
  # @return [String] The git command output
  def git(cmd, opts = {})
    raise_on_fail = opts.fetch(:raise_on_fail, true)

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
    subproc.raise_on_fail = raise_on_fail
    subproc.logger = self.logger

    result = subproc.execute

    result
  end
end
