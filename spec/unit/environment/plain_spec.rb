require 'spec_helper'
require 'r10k/environment'

describe R10K::Environment::Plain do
  it "initializes successfully" do
    expect(described_class.new('envname', '/basedir', 'dirname', {})).to be_a_kind_of(described_class)
  end
end
