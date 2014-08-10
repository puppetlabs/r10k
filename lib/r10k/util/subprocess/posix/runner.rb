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
class R10K::Util::Subprocess::POSIX::Runner < R10K::Util::Subprocess::Runner

  def initialize(argv)
    @argv = argv
    @io = R10K::Util::Subprocess::POSIX::IO.new

    attach_pipes
  end

  def start
    exec_r, exec_w = status_pipe()


    @pid = fork do
      exec_r.close
      execute_child(exec_w)
    end

    exec_w.close
    execute_parent(exec_r)
  end

  def wait
    if @pid
      _, @status = Process.waitpid2(@pid)
    end

    stdout = @stdout_r.read
    stderr = @stderr_r.read

    @stdout_r.close
    @stderr_r.close
    @result = R10K::Util::Subprocess::Result.new(@argv, stdout, stderr, @status.exitstatus)
  end

  def run
    start
    wait
    @result
  end

  def crashed?
    exit_code != 0
  end

  def exit_code
    @status.exitstatus
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
    STDOUT.reopen(io.stdout)
    STDERR.reopen(io.stderr)

    executable = @argv.shift
    exec([executable, executable], *@argv)
  rescue SystemCallError => e
    exec_w.write(e.message)
  end

  def execute_parent(exec_r)
    @stdout_w.close
    @stderr_w.close

    if not exec_r.eof?
      msg = exec_r.read || "exec() failed"
      raise "Could not execute #{@argv.join(' ')}: #{msg}"
    end
    exec_r.close
  end

  # Create a pipe so that the parent can verify that the child process
  # successfully executed. The pipe will be closed on a successful exec(),
  # and will contain an error message on failure.
  #
  # @return [IO, IO] The reader and writer for this pipe
  def status_pipe
    r_pipe, w_pipe = ::IO.pipe

    w_pipe.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)

    [r_pipe, w_pipe]
  end

  def attach_pipes
    @stdout_r, @stdout_w = ::IO.pipe
    @stderr_r, @stderr_w = ::IO.pipe

    @stdout_r.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
    @stdout_w.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
    @stderr_r.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
    @stderr_w.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)

    @io.stdout = @stdout_w
    @io.stderr = @stderr_w
  end
end
