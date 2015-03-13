require 'spec_helper'
require 'r10k/git'
require 'r10k/git/commit'

describe R10K::Git::Commit do

  let(:ref) { '96eeaba8c5069e31400a3dfcbeb37d016c1b1980' }
  let(:repo) { double('git repository') }
  subject { described_class.new(ref) }


  describe "determining if the commit can be resolved" do
    before do
      subject.repository = repo
    end

    it "is true if the commit can be rev-parsed" do
      expect(repo).to receive(:rev_parse).with(ref).and_return ref
      expect(subject).to be_resolvable
    end

    it "is true if the commit cannot be rev-parsed" do
      expect(repo).to receive(:rev_parse).with(ref).and_raise(R10K::Git::UnresolvableRefError, :ref => ref)
      expect(subject).to_not be_resolvable
    end
  end

  it "can be converted to a string" do
    expect(subject.to_s).to eq ref
  end

  it_behaves_like "a git ref"
  it_behaves_like "an immutable git ref"
end
