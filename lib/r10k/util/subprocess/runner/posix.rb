require 'r10k/util/subprocess/runner'
require 'r10k/util/subprocess/runner/pump'
require 'fcntl'

# Implement a POSIX command runner by using fork/exec.
#
# This implementation is optimized to run commands in the background, and has
# a few noteworthy implementation details.
#
# First off, when the child process is forked, it calls setsid() to detach from
# the controlling TTY. This has two main ramifications: sending signals will
# never be send to the forked process, and the forked process does not have
# access to stdin.
#
# @api private
class R10K::Util::Subprocess::Runner::POSIX < R10K::Util::Subprocess::Runner

  def initialize(argv)
    @argv = argv
    mkpipes
  end

  def run
    # Create a pipe so that the parent can verify that the child process
    # successfully executed. The pipe will be closed on a successful exec(),
    # and will contain an error message on failure.
    exec_r, exec_w = pipe

    @stdout_pump = R10K::Util::Subprocess::Runner::Pump.new(@stdout_r)
    @stderr_pump = R10K::Util::Subprocess::Runner::Pump.new(@stderr_r)
    @stdout_pump.start
    @stderr_pump.start

    pid = fork do
      exec_r.close
      execute_child(exec_w)
    end

    exec_w.close
    execute_parent(exec_r, pid)

    @result
  end

  private

  def execute_child(exec_w)
    if @cwd
      Dir.chdir @cwd
    end

    # Create a new session for the forked child. This prevents children from
    # ever being the foreground process on a TTY, which is almost always what
    # we want in r10k.
    Process.setsid

    # Reopen file descriptors
    STDOUT.reopen(@stdout_w)
    STDERR.reopen(@stderr_w)

    executable = @argv.shift
    exec([executable, executable], *@argv)
  rescue SystemCallError => e
    exec_w.write("#{e.class}: #{e.message}")
    exit(254)
  end

  def execute_parent(exec_r, pid)
    @stdout_w.close
    @stderr_w.close

    stdout = ''
    stderr = ''

    if !exec_r.eof?
      stderr = exec_r.read || "exec() failed"
      _, @status = Process.waitpid2(pid)
    else
      _, @status = Process.waitpid2(pid)
      @stdout_pump.halt!
      @stderr_pump.halt!
      stdout = @stdout_pump.string
      stderr = @stderr_pump.string
    end
    exec_r.close

    @stdout_r.close
    @stderr_r.close

    @result = R10K::Util::Subprocess::Result.new(@argv, stdout, stderr, @status.exitstatus)
  end

  def mkpipes
    @stdout_r, @stdout_w = pipe
    @stderr_r, @stderr_w = pipe
  end

  def pipe
    ::IO.pipe.tap do |pair|
      pair.each { |p| p.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC) }
    end
  end
end
