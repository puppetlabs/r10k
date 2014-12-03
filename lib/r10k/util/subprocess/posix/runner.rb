require 'fcntl'

module R10K::Util::Subprocess::POSIX; end

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
    mkpipes
  end

  def start
    # Create a pipe so that the parent can verify that the child process
    # successfully executed. The pipe will be closed on a successful exec(),
    # and will contain an error message on failure.
    exec_r, exec_w = pipe


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
    # Use non-blocking read for stderr_r to work around an issue with OpenSSH
    # ControlPersist: https://bugzilla.mindrot.org/show_bug.cgi?id=1988
    # Blocking should not occur in any other case since the process that was
    # attached to the pipe has already terminated.
    stderr = read_nonblock(@stderr_r)

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
    STDOUT.reopen(@stdout_w)
    STDERR.reopen(@stderr_w)

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

  def mkpipes
    @stdout_r, @stdout_w = pipe
    @stderr_r, @stderr_w = pipe
  end

  # Perform non-blocking reads on a pipe that could still be open
  # Give up on reaching EOF or blocking and return what was read
  def read_nonblock(rd_io)
    data = ''
    begin
      # Loop until EOF or blocking
      loop do
          # do an 8k non-blocking read and append the result
          data << rd_io.read_nonblock(8192)
      end
    rescue EOFError, Errno::EAGAIN, Errno::EWOULDBLOCK
    end
    data
  end

  def pipe
    ::IO.pipe.tap do |pair|
      pair.each { |p| p.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC) }
    end
  end
end
