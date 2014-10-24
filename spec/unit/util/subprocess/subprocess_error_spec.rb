require 'spec_helper'
require 'r10k/util/subprocess'

describe R10K::Util::Subprocess::SubprocessError do
  let(:result) do
    R10K::Util::Subprocess::Result.new(%w[/usr/bin/gti --zoom], "zooming on stdout", "zooming on stderr", 42)
  end

  describe "formatting the message" do
    subject(:message) { described_class.new("Execution failed", :result => result).message }

    it "includes the exception message and formatted result" do
      expect(message).to eq(
        [
          "Execution failed:",
          "Command: /usr/bin/gti --zoom",
          "Stdout:",
          "zooming on stdout",
          "Stderr:",
          "zooming on stderr",
          "Exit code: 42",
        ].join("\n")
      )
    end
  end
end
