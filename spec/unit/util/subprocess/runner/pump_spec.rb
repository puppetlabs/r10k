require 'spec_helper'
require 'r10k/util/subprocess/runner/pump'

describe R10K::Util::Subprocess::Runner::Pump do

  let(:pair) { IO.pipe }
  let(:r) { pair.first }
  let(:w) { pair.last }

  after do
    pair.each { |io| io.close unless io.closed? }
  end

  subject { described_class.new(r) }

  it "returns an empty string if nothing has been read" do
    expect(subject.string).to eq('')
  end

  describe "reading all data in the stream" do
    it "reads data until the stream reaches EOF" do
      subject.start
      w << "hello"
      w << " "
      w << "world!"
      w.close
      subject.wait
      expect(subject.string).to eq("hello world!")
    end
  end

  describe "halting" do
    it "does not read any more information read off the pipe" do
      subject.min_delay = 0.01
      subject.start
      w << "hello"

      # This should ensure that we yield to the pumping thread. If this test
      # sporadically fails then we may need to increase the timeout.
      sleep 0.1
      subject.halt!
      w << " world!"

      expect(subject.string).to eq("hello")
    end
  end

  # Linux 2.6.11+ has a maximum pipe capacity of 64 KiB, and writing to the
  # pipe when the pipe is at capacity will block. To make sure the pump is
  # actively removing contents from the pipe we need to attempt to fill up
  # the entire pipe.
  #
  # See man pipe(7)
  it "does not block if more than 64 kilobytes are fed into the pipe" do
    # The maximum pipe buffer size is 2 ** 16 bytes, so that's the minimum
    # amount of data needed to cause further writes to block. We then double
    # this value to make sure that we are continuously emptying the pipe.
    pipe_buffer_size = 2 ** 17
    blob = "buffalo!" * pipe_buffer_size
    subject.start
    Timeout.timeout(60) { w << blob }
    w.close
    subject.wait
  end
end
