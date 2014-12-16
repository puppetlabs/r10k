require 'r10k/util/subprocess/runner'

# Perform nonblocking reads on a streaming IO instance.
#
# @api private
class R10K::Util::Subprocess::Runner::Pump

  # !@attribute [r] string
  #   @return [String] The output collected from the IO instance
  attr_reader :string

  attr_accessor :delay

  def initialize(io)
    @io     = io
    @thread = nil
    @string = ''
    @run    = true
    @delay  = 0.001
  end

  def start
    @thread = Thread.new { pump }
  end

  def halt!
    @run = false
    @thread.join
  end

  # Block until the pumping thread reaches EOF on the IO object.
  def wait
    @thread.join
  end

  private

  def pump
    backoff = @delay
    while @run
      begin
        @string << @io.read_nonblock(4096)
        backoff /= 2 if backoff > @delay
      rescue Errno::EWOULDBLOCK, Errno::EAGAIN
        backoff *= 2
        IO.select([@io], [], [], @delay)
      rescue EOFError
        @run = false
      end
    end
  end
end
