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

  def initialize(ref, repository = nil)
    @ref = ref
    @repository = repository
  end

  def sha1
    if @repository.nil?
      raise ArgumentError, "Cannot resolve #{self.inspect}: not associated git repository"
    else
      @repository.rev_parse(@ref)
    end
  end

  def ==(other)
    other.sha1 == self.sha1
  end

  def to_s
    @ref
  end
end
