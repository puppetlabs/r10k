require 'spec_helper'
require 'r10k/git'
require 'r10k/git/head'

describe R10K::Git::Head do

  let(:ref) { 'git/branch' }
  let(:repo) { double('git repository') }
  subject { described_class.new(ref) }

  describe "determining if the head needs to be fetched" do
    it "is always true" do
      expect(subject.fetch?).to be_truthy
    end
  end

  it "can be converted to a string" do
    expect(subject.to_s).to eq ref
  end

  it_behaves_like "a git ref"
end
