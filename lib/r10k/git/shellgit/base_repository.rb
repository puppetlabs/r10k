require 'r10k/git/shellgit'
require 'r10k/logging'
require 'r10k/util/subprocess'

class R10K::Git::ShellGit::BaseRepository

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

  # @return [Array<String>] All local branches in this repository
  def branches
    for_each_ref('refs/heads')
  end

  # @return [Array<String>] All tags in this repository
  def tags
    for_each_ref('refs/tags')
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

  # @param pattern [String]
  def for_each_ref(pattern)
    matcher = %r[#{pattern}/(.*)$]
    output = git ['for-each-ref', pattern, '--format', '%(refname)'], :git_dir => git_dir.to_s
    output.stdout.scan(matcher).flatten
  end

  def git(cmd, opts = {})
    R10K::Git::ShellGit.git(cmd, opts)
  end

end
