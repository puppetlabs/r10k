require 'spec_helper'
require 'r10k/errors/formatting'

describe R10K::Errors::Formatting do

  describe "without a nested exception" do
    let(:exc) do
      ArgumentError.new("ArgumentError message").tap do |a|
        a.set_backtrace(%w[/backtrace/line:1 /backtrace/line:2])
      end
    end

    describe "and without a backtrace" do
      subject do
        described_class.format_exception(exc, false)
      end

      it "formats the exception with the message" do
        expect(subject).to eq("ArgumentError message")
      end
    end

    describe "and with a backtrace" do
      subject do
        described_class.format_exception(exc, true)
      end

      it "formats the exception with the message and backtrace" do
        expect(subject).to eq([
          "ArgumentError message",
          "/backtrace/line:1",
          "/backtrace/line:2",
        ].join("\n"))
      end
    end
  end

  describe "with a nested exception" do

    let(:nestee) do
      ArgumentError.new("ArgumentError message").tap do |a|
        a.set_backtrace(%w[/backtrace/line:1 /backtrace/line:2])
      end
    end

    let(:exc) do
      R10K::Error.wrap(nestee, "R10K::Error message").tap do |r|
        r.set_backtrace(%w[/another/backtrace/line:1 /another/backtrace/line:2])
      end
    end

    describe "and without a backtrace" do
      subject do
        described_class.format_exception(exc, false)
      end

      it "formats the exception with the message and original message" do
        expect(subject).to eq([
          "R10K::Error message",
          "Original:",
          "ArgumentError message"
        ].join("\n"))
      end
    end

    describe "and with a backtrace" do
      subject do
        described_class.format_exception(exc, true)
      end

      it "formats the exception with the message, backtrace, original message, and original backtrace" do
        expect(subject).to eq([
          "R10K::Error message",
          "/another/backtrace/line:1",
          "/another/backtrace/line:2",
          "Original:",
          "ArgumentError message",
          "/backtrace/line:1",
          "/backtrace/line:2",
        ].join("\n"))
      end
    end
  end
end
