require 'spec_helper'
require 'r10k/source'

describe R10K::Source do
  it "implementds methods for a keyed factory" do
    expect(described_class).to respond_to :register
    expect(described_class).to respond_to :retrieve
    expect(described_class).to respond_to :generate
  end
end
