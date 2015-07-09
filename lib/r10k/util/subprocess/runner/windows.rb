require 'open3'
require 'r10k/util/subprocess/runner'

# Run processes on Windows.
#
# This implementation relies on Open3.capture3 to run commands and capture
# results. In contrast to the POSIX runner this cannot be used in an
# asynchronous manner as-is; implementing that will probably mean launching a
# thread and invoking #capture3 in that thread.
class R10K::Util::Subprocess::Runner::Windows < R10K::Util::Subprocess::Runner

  def initialize(argv)
    @argv = argv
  end

  def run
    stdout, stderr, status = Open3.capture3(*@argv)
    @result = R10K::Util::Subprocess::Result.new(@argv, stdout, stderr, status.exitstatus)
  end
end
