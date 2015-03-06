require 'r10k/util/subprocess/runner'
require 'r10k/util/subprocess/runner/pump'
require 'childprocess'

class R10K::Util::Subprocess::Runner::Childprocess < R10K::Util::Subprocess::Runner

  def initialize(argv)
    @argv = argv
  end

  def run
    process = ChildProcess.build(*@argv)
    process.cwd = @cwd if @cwd

    stdout = ''
    stderr = ''
    exit_code = 254

    stdout_r, stdout_w = IO.pipe
    stderr_r, stderr_w = IO.pipe

    stdout_pump = R10K::Util::Subprocess::Runner::Pump.new(stdout_r)
    stderr_pump = R10K::Util::Subprocess::Runner::Pump.new(stderr_r)

    process.io.stdout = stdout_w
    process.io.stderr = stderr_w

    begin
      stdout_pump.start
      stderr_pump.start
      process.start
      process.wait
      stdout_pump.halt!
      stderr_pump.halt!

      stdout = stdout_pump.string
      stderr = stderr_pump.string

      exit_code = process.exit_code
    rescue ChildProcess::LaunchError => e
      stderr = e.message
    end

    @result = R10K::Util::Subprocess::Result.new(@argv, stdout, stderr, exit_code)
  ensure
    [stdout_r, stdout_w, stderr_r, stderr_w].each { |io| io.close }
  end
end
