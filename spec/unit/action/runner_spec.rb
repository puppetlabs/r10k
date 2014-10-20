require 'spec_helper'
require 'r10k/action/runner'


describe R10K::Action::Runner do

  let(:action_class) do
    Class.new do
      attr_reader :opts
      attr_reader :argv

      def initialize(opts, argv)
        @opts = opts
        @argv = argv
      end

      def call
        @argv.map(&:upcase)
      end
    end
  end

  subject(:runner) { described_class.new({:opts => :yep}, %w[args yes], action_class) }

  describe "instantiating the wrapped class" do
    it "creates an instance of the class" do
      expect(runner.instance).to be_a_kind_of action_class
    end

    it "passes the opts and argv to the instance" do
      expect(runner.instance.opts).to eq(:opts => :yep)
      expect(runner.instance.argv).to eq(%w[args yes])
    end

    it "strips out options that the runner handles" do
      runner = described_class.new({:opts => :yep, :loglevel => 'FATAL'}, %w[args yes], action_class)
      expect(runner.instance.opts).to eq(:opts => :yep)
    end
  end

  describe "calling" do
    it "configures logging" do
      expect(runner).to receive(:setup_logging)
      runner.call
    end

    it "returns the result of the wrapped class #call method" do
      expect(runner.call).to eq %w[ARGS YES]
    end
  end

  describe "configuring logging" do
    it "sets the log level if :loglevel is provided" do
      runner = described_class.new({:opts => :yep, :loglevel => 'FATAL'}, %w[args yes], action_class)
      expect(R10K::Logging).to receive(:level=).with('FATAL')
      runner.call
    end

    it "does not modify the loglevel if :loglevel is not provided" do
      expect(R10K::Logging).to_not receive(:level=)
      runner.call
    end
  end
end
