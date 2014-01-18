require 'spec_helper'
require 'r10k/git'

describe R10K::Git::Head do

  let(:ref) { 'git/branch' }
  let(:repo) { double('git repository') }
  subject { described_class.new(ref) }


  describe "determining if the head can be resolved" do
    it "is always false"
  end

  it "can be converted to a string" do
    expect(subject.to_s).to eq ref
  end

  it_behaves_like "a git ref"
end

