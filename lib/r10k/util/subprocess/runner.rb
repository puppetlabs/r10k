# Define an abstract interface for external command runners.
#
# @api private
class R10K::Util::Subprocess::Runner

  require 'r10k/util/subprocess/runner/windows'
  require 'r10k/util/subprocess/runner/posix'

  # @!attribute [rw] cwd
  #   @return [String] The directory to be used as the cwd when executing
  #     the command.
  attr_accessor :cwd

  # @!attribute [r] result
  #   @return [R10K::Util::Subprocess::Result]
  attr_reader :result

  def initialize(argv)
    raise NotImplementedError
  end

  def run
    raise NotImplementedError
  end
end
