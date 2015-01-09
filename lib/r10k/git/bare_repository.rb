require 'r10k/git'
require 'r10k/logging'

# Create and manage Git bare repositories.
class R10K::Git::BareRepository

  # @return [Pathname] The path to this Git repository
  def git_dir
    @path.to_s
  end

  # @param basedir [String] The base directory of the Git repository
  # @param dirname [String] The directory name of the Git repository
  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))
  end

  def clone(remote)
    git ['clone', '--mirror', remote, git_dir]
  end

  def fetch
    git ['fetch', '--prune'], :git_dir => git_dir
  end

  def exist?
    @path.exist?
  end

  # @return [Array<String>] All local branches in this repository
  def branches
    output = git %w[for-each-ref refs/heads --format %(refname)], :git_dir => git_dir
    output.stdout.scan(%r[refs/heads/(.*)$]).flatten
  end

  # @return [Array<String>] All tags in this repository
  def tags
    output = git %w[for-each-ref refs/tags --format %(refname)], :git_dir => git_dir
    output.stdout.scan(%r[refs/tags/(.*)$]).flatten
  end

  # Resolve the given Git ref to a commit
  #
  # @param pattern [String] The git ref to resolve
  # @return [String, nil] The commit SHA if the ref could be resolved, nil otherwise.
  def resolve(pattern)
    result = git ['rev-parse', "#{pattern}^{commit}"], :git_dir => git_dir, :raise_on_fail => false
    if result.success?
      result.stdout
    end
  end

  # @return [Symbol] The type of the given ref, one of :branch, :tag, :commit, or :unknown
  def ref_type(pattern)
    if branches.include? pattern
      :branch
    elsif tags.include? pattern
      :tag
    elsif resolve(pattern)
      :commit
    else
      :unknown
    end
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
