# Define an abstract interface for external command runners.
#
# @api private
class R10K::Util::Subprocess::Runner

  require 'r10k/util/subprocess/windows/runner'
  require 'r10k/util/subprocess/posix/runner'

  # @!attribute [rw] cwd
  #   @return [String] The directory to be used as the cwd when executing
  #     the command.
  attr_accessor :cwd

  attr_reader :pid

  # @!attribute [r] status
  #   @return [Process::Status]
  attr_reader :status

  # @!attribute [r] result
  #   @return [R10K::Util::Subprocess::Result]
  attr_reader :result

  def initialize(argv)
    raise NotImplementedError
  end

  def run
    raise NotImplementedError
  end

  # Start the process asynchronously and return. Not all runners will implement this.
  def start
    raise NotImplementedError
  end

  # Wait for the process to exit. Not all runners will implement this.
  def wait
    raise NotImplementedError
  end

  # Did the given process exit with a non-zero exit code?
  def crashed?
    raise NotImplementedError
  end

  # @return [Integer] The exit status of the given process.
  def exit_code
    raise NotImplementedError
  end
end
