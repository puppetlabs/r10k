require 'spec_helper'
require 'r10k/logging'

describe R10K::Logging do

  describe "parsing a log level" do
    it "parses 'true:TrueClass' as INFO" do
      expect(described_class.parse_level(true)).to eq Log4r::INFO
    end

    it "parses 'true:String' as nil" do
      expect(described_class.parse_level("true")).to be_nil
    end

    it "parses a numeric string as an integer" do
      expect(described_class.parse_level('2')).to eq 2
    end

    it "parses a log level string as a log level" do
      expect(described_class.parse_level('debug')).to eq Log4r::DEBUG
    end

    it "returns nil when given an invalid log level" do
      expect(described_class.parse_level('deblag')).to be_nil
    end
  end

  describe "setting the log level" do
    after(:all) { R10K::Logging.level = 'warn' }

    it "sets the outputter log level" do
      expect(described_class.outputter).to receive(:level=).with(Log4r::DEBUG)
      described_class.level = 'debug'
    end

    it "stores the new log level" do
      allow(described_class.outputter).to receive(:level=)
      described_class.level = 'debug'
      expect(described_class.level).to eq(Log4r::DEBUG)
    end

    it "raises an exception when given an invalid log level" do
      expect {
        described_class.level = 'deblag'
      }.to raise_error(ArgumentError, /Invalid log level/)
    end

    describe "switching the formatter" do
      before do
        allow(described_class.outputter).to receive(:level=)
      end

      it "switches to the debug formatter if the new log level is debug or greater" do
        debug_formatter = double('debug formatter')
        expect(described_class).to receive(:debug_formatter).and_return(debug_formatter)
        expect(described_class.outputter).to receive(:formatter=).with(debug_formatter)
        described_class.level = 'debug'
      end

      it "switches to the default formatter if the new log level is info or less" do
        default_formatter = double('default formatter')
        expect(described_class).to receive(:default_formatter).and_return(default_formatter)
        expect(described_class.outputter).to receive(:formatter=).with(default_formatter)
        described_class.level = 'info'
      end
    end
  end
end
