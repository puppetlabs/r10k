require 'spec_helper'
require 'r10k/git'

describe R10K::Git::Commit do

  let(:ref) { '96eeaba8c5069e31400a3dfcbeb37d016c1b1980' }
  let(:repo) { double('git repository') }
  subject { described_class.new(ref) }


  describe "determining if the commit can be resolved" do
    it "is true if the commit has been fetched"
    it "is false if the commit cannot be resolved"
  end

  it "can be converted to a string" do
    expect(subject.to_s).to eq ref
  end

  it_behaves_like "a git ref"
end
