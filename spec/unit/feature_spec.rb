require 'spec_helper'
require 'r10k/feature'

describe R10K::Feature do
  describe "confining a feature to a library" do
    it "is available if the library can be loaded" do
      feature = described_class.new(:r10k, :libraries => 'r10k')
      expect(feature.available?).to be_truthy
    end

    it "is unavailable if the library cannot be loaded" do
      feature = described_class.new(:squidlibs, :libraries => 'squid/libs')
      expect(feature.available?).to be_falsey
    end
  end

  describe "confining a feature to a block" do
    it "is available if the block is true" do
      feature = described_class.new(:blockfeature) { true }
      expect(feature.available?).to be_truthy
    end

    it "is unavailable if the block is false" do
      feature = described_class.new(:blockfeature) { false }
      expect(feature.available?).to be_falsey
    end
  end

  describe  "confining a feature to both a block and libraries" do
    it "is unavailable if the block returns false and libraries are absent" do
      feature = described_class.new(:nope, :libraries => 'nope/nope') { false }
      expect(feature.available?).to be_falsey
    end

    it "is unavailable if the block returns true and libraries are absent" do
      feature = described_class.new(:nope, :libraries => 'nope/nope') { true }
      expect(feature.available?).to be_falsey
    end

    it "is unavailable if the block returns false and libraries are present" do
      feature = described_class.new(:nope, :libraries => 'r10k') { false }
      expect(feature.available?).to be_falsey
    end

    it "is available if the block returns true and libraries are present" do
      feature = described_class.new(:yep, :libraries => 'r10k') { true }
      expect(feature.available?).to be_truthy
    end
  end
end
