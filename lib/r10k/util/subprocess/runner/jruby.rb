require 'open3'
require 'r10k/util/subprocess/runner'

# Run processes under JRuby.
#
# This implementation relies on Open3.capture3 to run commands and capture
# results. In contrast to the POSIX runner this cannot be used in an
# asynchronous manner as-is; implementing that will probably mean launching a
# thread and invoking #capture3 in that thread.
class R10K::Util::Subprocess::Runner::JRuby < R10K::Util::Subprocess::Runner

  def initialize(argv)
    @argv = argv
  end

  def run
    spawn_opts = @cwd ? {:chdir => @cwd} : {}
    stdout, stderr, status = Open3.capture3(*@argv, spawn_opts)
    @result = R10K::Util::Subprocess::Result.new(@argv, stdout, stderr, status.exitstatus)
  rescue Errno::ENOENT, Errno::EACCES => e
    @result = R10K::Util::Subprocess::Result.new(@argv, '', e.message, 255)
  end
end
