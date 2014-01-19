require 'r10k/git/ref'
require 'r10k/git/repository'

# tag: A ref under refs/tags/ namespace that points to an object of an
# arbitrary type (typically a tag points to either a tag or a commit object).
# In contrast to a head, a tag is not updated by the commit command. A tag is
# most typically used to mark a particular point in the commit ancestry chain.
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

  # Can we locate the commit in the related repository?
  def resolvable?
    sha1
    true
  rescue R10K::Git::NonexistentHashError
    false
  end

  def fetch?
    ! resolvable?
  end

  def sha1
    if @repository.nil?
      raise ArgumentError, "Cannot resolve #{self.inspect}: no associated git repository"
    else
      @repository.rev_parse(@tag, :tag)
    end
  end
end
