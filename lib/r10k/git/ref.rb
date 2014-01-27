require 'r10k/git'
require 'r10k/git/repository'

# ref: A 40-byte hex representation of a SHA1 or a name that denotes a
# particular object. They may be stored in a file under $GIT_DIR/refs/
# directory, or in the $GIT_DIR/packed-refs file.
#
# @see https://www.kernel.org/pub/software/scm/git/docs/gitglossary.html
# @api private
class R10K::Git::Ref

  # @!attribute [r] ref
  #   @return [String] The git reference
  attr_reader :ref

  # @!attribute [rw] repository
  #   @return [R10K::Git::Repository] A git repository that can be used to
  #     resolve the git reference to a commit.
  attr_accessor :repository

  def initialize(ref, repository = nil)
    @ref = ref
    @repository = repository
  end

  # Can we locate the commit in the related repository?
  def resolvable?
    sha1
    true
  rescue R10K::Git::NonexistentHashError
    false
  end

  # Should we try to fetch this ref?
  #
  # Since we don't know the type of this ref, we have to assume that it might
  # be a branch and always update accordingly.
  def fetch?
    true
  end

  def sha1
    if @repository.nil?
      raise ArgumentError, "Cannot resolve #{self.inspect}: no associated git repository"
    else
      @repository.rev_parse(ref)
    end
  end

  def ==(other)
    other.sha1 == self.sha1
  rescue ArgumentError, R10K::Git::NonexistentHashError
    false
  end

  def to_s
    ref
  end

  def inspect
    "#<#{self.class}: #{to_s}>"
  end
end
