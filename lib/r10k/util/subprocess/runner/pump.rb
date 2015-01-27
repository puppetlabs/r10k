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
    @min_delay = 0.001
    @max_delay = 1.0
    @mutex = Mutex.new
    @halting = false
    @waiting = false
  end

  def start
    @thread = Thread.new { pump }
  end

  # Exit immediately after the current pump cycle
  def halt!
    @halting = true
    @thread.join
  end

  # Block until the pumping thread reaches EOF or until select times out
  # checking for updates on the IO object
  def wait
    @mutex.synchronize { @waiting = true }
    @thread.join
  end

  private

  def pump
    backoff = @min_delay
    until @halting
      begin
        @string << @io.read_nonblock(4096)
        backoff /= 2 if backoff > @min_delay
      rescue Errno::EWOULDBLOCK, Errno::EAGAIN
        backoff *= 2 if backoff < @max_delay
        @mutex.synchronize do
          ready_fds = IO.select([@io], [], [], backoff)
          @halting = true if @waiting && !ready_fds
        end
      rescue EOFError
        @halting = true
      end
    end
  end
end
