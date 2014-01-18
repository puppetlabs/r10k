require 'r10k/git'
require 'r10k/git/ref'
require 'r10k/git/repository'


# head: A named reference to the commit at the tip of a branch. Heads are
# stored in a file in $GIT_DIR/refs/heads/ directory. except when using packed
#
# @see https://www.kernel.org/pub/software/scm/git/docs/gitglossary.html
# @api private
class R10K::Git::Head < R10K::Git::Ref

  # @!attribute [r] head
  #   @return [String] The git head
  attr_reader :head
  alias :ref :head

  def initialize(head, repository = nil)
    @head = head
    @repository = repository
  end

  # def sha1
  #   TODO ensure that @head is an actual head as opposed to a tag or other
  #   hooliganism.
  #end
end
