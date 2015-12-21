require 'open3'
require 'r10k/util/subprocess/runner'
require 'r10k/util/subprocess/result'
require 'r10k/logging'

# Run processes under JRuby.
#
# This implementation relies on Open3.capture3 to run commands and capture
# results. In contrast to the POSIX runner this cannot be used in an
# asynchronous manner as-is; implementing that will probably mean launching a
# thread and invoking #capture3 in that thread.
class R10K::Util::Subprocess::Runner::JRuby < R10K::Util::Subprocess::Runner
  include R10K::Logging

  def initialize(argv)
    @argv = argv
  end

  def run
    logger.warn("Modifying working directory for subprocess is not supported under JRuby") if @cwd

    stdout, stderr, status = Open3.capture3(@argv.join(' '))
    @result = R10K::Util::Subprocess::Result.new(@argv, stdout, stderr, status.exitstatus)
  rescue Errno::ENOENT, Errno::EACCES => e
    @result = R10K::Util::Subprocess::Result.new(@argv, '', e.message, 255)
  end
end
