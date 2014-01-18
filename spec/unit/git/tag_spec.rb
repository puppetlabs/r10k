require 'spec_helper'
require 'r10k/git'

describe R10K::Git::Tag do

  let(:ref) { '0.1.0' }
  let(:repo) { double('git repository') }
  subject { described_class.new(ref) }


  describe "determining if the tag can be resolved" do
    it "is true if the tag has been fetched"
    it "is false if the tag cannot be resolved"
  end

  it "can be converted to a string" do
    expect(subject.to_s).to eq ref
  end

  it_behaves_like "a git ref"
end
