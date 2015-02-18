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
end
