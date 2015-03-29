require 'r10k/git/ref'
require 'r10k/git/repository'

# tag: A ref under refs/tags/ namespace that points to an object of an
# arbitrary type (typically a tag points to either a tag or a commit object).
# In contrast to a head, a tag is not updated by the commit command. A tag is
# most typically used to mark a particular point in the commit ancestry chain.
#
# @deprecated This has been replaced by the ShellGit provider and the
#   StatefulRepository class and will be removed in 2.0.0
#
# @see https://www.kernel.org/pub/software/scm/git/docs/gitglossary.html
# @api private
class R10K::Git::Tag < R10K::Git::Ref

  # @!attribute [r] tag
  #   @return [String] The git tag
  attr_reader :tag
  alias :ref :tag

  def initialize(tag, repository = nil)
    @tag = tag
    @repository = repository
  end

  def fetch?
    ! resolvable?
  end
end
