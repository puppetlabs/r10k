require 'r10k/git'
require 'r10k/util/subprocess'

# Define an abstract base class for git repositories.
#
# @deprecated This has been replaced by the ShellGit provider and the
#   StatefulRepository class and will be removed in 2.0.0
#
# :nocov:
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

  # Resolve a ref to a git commit. The given pattern can be a commit, tag,
  # or a local or remote branch
  #
  # @param [String] pattern
  #
  # @return [String] The dereferenced hash of `pattern`
  def resolve_ref(pattern)
    commit   = resolve_tag(pattern)
    commit ||= resolve_remote_head(pattern)
    commit ||= resolve_head(pattern)
    commit ||= resolve_commit(pattern)

    if commit
      commit.chomp
    else
      raise R10K::Git::UnresolvableRefError.new("Could not resolve Git ref '#{ref}'", :ref => pattern, :git_dir => git_dir)
    end
  end
  alias rev_parse resolve_ref

  def resolve_tag(pattern)
    output = git ['show-ref', '--tags', '-s', pattern], :git_dir => git_dir, :raise_on_fail => false

    if output.success?
      output.stdout.lines.first
    end
  end

  def resolve_head(pattern)
    output = git ['show-ref', '--heads', '-s', pattern], :git_dir => git_dir, :raise_on_fail => false

    if output.success?
      output.stdout.lines.first
    end
  end

  def resolve_remote_head(pattern, remote = 'origin')
    pattern = "refs/remotes/#{remote}/#{pattern}"
    output = git ['show-ref', '-s', pattern], :git_dir => git_dir, :raise_on_fail => false

    if output.success?
      output.stdout.lines.first
    end
  end

  # Define the same interface for resolving refs.
  def resolve_commit(pattern)
    output = git ['rev-parse', "#{pattern}^{commit}"], :git_dir => git_dir, :raise_on_fail => false

    if output.success?
      output.stdout.chomp
    end
  end

  # @return [Hash<String, String>] A hash of remote names and fetch URLs
  # @api private
  def remotes
    output = git ['remote', '-v'], :git_dir => git_dir

    ret = {}
    output.stdout.each_line do |line|
      next if line.match(/\(push\)/)
      name, url, _ = line.split(/\s+/)
      ret[name] = url
    end

    ret
  end

  def tags
    entries = []
    output = git(['tag', '-l'], :git_dir => @git_dir).stdout
    output.each_line { |line| entries << line.chomp }
    entries
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
# :nocov:
