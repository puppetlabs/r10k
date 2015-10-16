require 'spec_helper'
require 'r10k/action/base'
require 'r10k/action/cri_runner'

describe R10K::Action::CriRunner do

  let(:action_class) do
    Class.new do
      attr_reader :opts
      attr_reader :argv

      def initialize(opts, argv, settings = {})
        @opts = opts
        @argv = argv
        @settings = {}
      end

      def call
        @opts[:runok]
      end
    end
  end

  subject(:cri_runner) { described_class.wrap(action_class)  }

  let(:opts) { {:value => :yep} }
  let(:argv) { %w[value yes] }

  describe "handling options" do
    it "adapts the :verbose flag to :loglevel" do
      input = {:value => :yep, :verbose => 'DEBUG'}
      output = {:value => :yep, :loglevel => 'DEBUG'}
      expect(cri_runner.handle_opts(input)).to eq(output)
    end
  end

  describe "handling arguments" do
    it "sets the arguments as-is" do
      expect(cri_runner.handle_argv(%w[one two])).to eq(%w[one two])
    end
  end

  describe "proxying invocations to .new" do
    it "returns itself" do
      expect(cri_runner.new(opts, argv, :cri_cmd)).to eql cri_runner
    end

    it "handles options" do
      expect(cri_runner).to receive(:handle_opts)
      cri_runner.new({:value => :yep, :verbose => 'DEBUG'}, argv, :cri_cmd)
    end

    it "handles arguments" do
      expect(cri_runner).to receive(:handle_argv)
      cri_runner.new({:value => :yep, :verbose => 'DEBUG'}, argv, :cri_cmd)
    end
  end

  describe "calling" do
    it "exits with a return value of 0 if the action returned true" do
      expect {
        cri_runner.new({:runok => true}, []).call
      }.to exit_with(0)
    end

    it "exits with a return value of 1 if the action returned false" do
      expect {
        cri_runner.new({:runok => false}, []).call
      }.to exit_with(1)
    end
  end
end
