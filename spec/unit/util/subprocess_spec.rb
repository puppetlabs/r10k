require 'spec_helper'
require 'r10k/util/subprocess'

describe R10K::Util::Subprocess do

  describe "selecting the runner implementation" do
    it "uses the windows implementation on Windows platforms" do
      expect(R10K::Util::Platform).to receive(:windows?).and_return true
      expect(described_class.runner).to eq R10K::Util::Subprocess::Runner::Windows
    end

    it "uses the posix implementation when not on windows" do
      expect(R10K::Util::Platform).to receive(:windows?).and_return true
      expect(described_class.runner).to eq R10K::Util::Subprocess::Runner::Windows
    end
  end

  describe "running commands" do
    subject { described_class.new(['/bin/echo', 'hello', 'world']) }

    let(:runner) do
      double('R10K::Util::Subprocess::Runner').tap do |i|
        allow(i).to receive(:run).and_return(result)
      end
    end

    let(:result) { double('R10K::Util::Subprocess::Result').as_null_object }

    before do
      allow(described_class).to receive(:runner).and_return(double(:new => runner))
    end

    it "copies the cwd to the runner if a cwd is given" do
      expect(runner).to receive(:cwd=).with('/tmp')
      subject.cwd = '/tmp'
      subject.execute
    end

    it "returns the result from the execution" do
      expect(subject.execute).to eq result
    end

    describe "when the command returned with a non-zero exit status" do
      before do
        allow(runner).to receive(:crashed?).and_return true
      end

      it "raises an exception if raise_on_fail is true" do
        subject.raise_on_fail = true

        allow(result).to receive(:exit_code).and_return(255)
        allow(result).to receive(:stderr).and_return('Command not found')

        expect {
          subject.execute
        }.to raise_error(R10K::Util::Subprocess::SubprocessError, /Command exited with non-zero exit code/)
      end

      it "doesn't raise an exception if raise_on_fail is false" do
        subject.raise_on_fail = false
        expect { subject.execute }.to_not raise_error
      end
    end
  end
end
