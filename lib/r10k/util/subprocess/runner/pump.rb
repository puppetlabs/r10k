require 'r10k/util/subprocess/runner'

# Perform nonblocking reads on a streaming IO instance.
#
# @api private
class R10K::Util::Subprocess::Runner::Pump

  # !@attribute [r] string
  #   @return [String] The output collected from the IO device
  attr_reader :string

  # @!attribute [r] min_delay
  #   @return [Float] The minimum time to wait while polling the IO device
  attr_accessor :min_delay

  # @!attribute [r] max_delay
  #   @return [Float] The maximum time to wait while polling the IO device
  attr_accessor :max_delay

  def initialize(io)
    @io     = io
    @thread = nil
    @string = ''
    @run    = true
    @min_delay = 0.1
    @max_delay = 1.0
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
    backoff = @min_delay
    while @run
      begin
        @string << @io.read_nonblock(4096)
        backoff /= 2 if backoff > @min_delay
      rescue Errno::EWOULDBLOCK, Errno::EAGAIN
        backoff *= 2 if backoff < @max_delay
        IO.select([@io], [], [], backoff)
      rescue EOFError
        @run = false
      end
    end
  end
end
