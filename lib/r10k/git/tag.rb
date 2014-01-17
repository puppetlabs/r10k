require 'r10k/git'
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

  # TODO only fetch if the tag cannot be resolved to a commit
  def resolvable?
    true
  end

  def sha1
    if @repository.nil?
      raise ArgumentError, "Cannot resolve #{self.inspect}: not associated git repository"
    else
      @repository.rev_parse(@tag, 'tag')
    end
  end
end
