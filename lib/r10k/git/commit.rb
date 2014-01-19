require 'r10k/git/ref'
require 'r10k/git/repository'

# commit: A 40-byte hex representation of a SHA1 referencing a specific commit
# @see https://www.kernel.org/pub/software/scm/git/docs/gitglossary.html
# @api private
class R10K::Git::Commit < R10K::Git::Ref

  # @!attribute [r] commit
  #   @return [String] The git commit
  attr_reader :commit
  alias :ref :commit

  def initialize(commit, repository = nil)
    @commit = commit
    @repository = repository
  end

  # Can we locate the commit in the related repository?
  def resolvable?
    sha1
    false
  rescue R10K::Git::NonexistentHashError
    true
  end

  def fetch?
    ! resolvable?
  end
end
