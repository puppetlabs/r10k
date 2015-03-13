require 'spec_helper'
require 'r10k/git'
require 'r10k/git/tag'

describe R10K::Git::Tag do

  let(:ref) { '0.1.0' }
  let(:repo) { double('git repository') }
  subject { described_class.new(ref) }


  describe "determining if the tag can be resolved" do
    it "is true if the tag has been fetched" do
      expect(repo).to receive(:rev_parse).with(ref).and_return('32f8ec692906783ee60e02e4a4154bc3a87dfeb6')
      subject.repository = repo
      expect(subject).to be_resolvable
    end

    it "is false if the tag cannot be resolved" do
      expect(repo).to receive(:rev_parse).with(ref).and_raise(R10K::Git::UnresolvableRefError, :ref => ref)
      subject.repository = repo
      expect(subject).to_not be_resolvable
    end
  end

  it "can be converted to a string" do
    expect(subject.to_s).to eq ref
  end

  it_behaves_like "a git ref"
  it_behaves_like "an immutable git ref"
end
