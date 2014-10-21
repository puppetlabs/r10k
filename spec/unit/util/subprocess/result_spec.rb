require 'spec_helper'
require 'r10k/util/subprocess'

describe R10K::Util::Subprocess::Result do
  describe "formatting" do
    it "includes the exit code" do
      result = described_class.new(%w[/usr/bin/gti --zoom], '', '', 42)
      expect(result.format).to match(%r[Exit code: 42])
    end

    describe "stdout" do
      it "is omitted when empty" do
        result = described_class.new(%w[/usr/bin/gti --zoom], '', '', 42)
        expect(result.format).to_not match(%r[Stdout])
      end
      it "is included when non-empty" do
        result = described_class.new(%w[/usr/bin/gti --zoom], 'stuff here', '', 42)
        expect(result.format).to match(%r[Stdout:])
        expect(result.format).to match(%r[stuff here])
      end
    end

    describe "stderr" do
      it "is omitted when empty" do
        result = described_class.new(%w[/usr/bin/gti --zoom], '', '', 42)
        expect(result.format).to_not match(%r[Stderr])
      end

      it "is included when non-empty" do
        result = described_class.new(%w[/usr/bin/gti --zoom], '', 'other stuff', 42)
        expect(result.format).to match(%r[Stderr:])
        expect(result.format).to match(%r[other stuff])
      end
    end
  end
end
