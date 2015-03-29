require 'spec_helper'
require 'stringio'
require 'r10k/logging/terminaloutputter'

describe R10K::Logging::TerminalOutputter do

  let(:stream) { StringIO.new }

  let(:formatter) do
    Class.new(Log4r::Formatter) do
      def format(logevent)
        logevent.data
      end
    end
  end

  subject do
    described_class.new('test', stream, :level => 0, :formatter => formatter).tap do |o|
      o.use_color = true
    end
  end

  tests = [
    [:debug2, :cyan],
    [:debug1, :cyan],
    [:debug,  :green],
    [:info,   nil],
    [:notice, nil],
    [:warn,   :yellow],
    [:error,  :red],
    [:fatal,  :red],
  ]

  tests.each_with_index do |(level, color), index|
    # Note for the unwary - using a loop in this manner shows strange
    # behavior with variable closure. The describe block is needed to retain
    # the loop variables for each test; without this the let helpers are
    # overwritten and the last set of helpers are used for all tests.
    describe "at level #{level}" do
      let(:message) { "level #{level}: #{color}" }

      let(:event) do
        Log4r::LogEvent.new(index + 1, Log4r::Logger.new('test::logger'), nil, message)
      end

      it "logs messages as #{color ? color : "uncolored"}" do
        output = color.nil? ? message : message.send(color)
        subject.send(level, event)
        expect(stream.string).to eq output
      end
    end
  end
end
