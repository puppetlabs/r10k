require 'spec_helper'
require 'r10k/git'

describe R10K::Git::Ref do

  let(:ref) { 'master' }
  let(:repo) { double('git repository') }
  subject { described_class.new(ref) }

  describe "fetching the SHA1" do
    it "raises an error if there is not a linked repository" do
      expect {
        subject.sha1
      }.to raise_error(ArgumentError, /Cannot resolve .*#{ref}.*: no associated git repository/)
    end

    it "raises an error if the SHA1 could not be resolved" do
      subject.repository = repo
      expect(repo).to receive(:rev_parse).with(ref).and_raise(R10K::Git::UnresolvableRefError, "Couldn't resolve")

      expect {
        subject.sha1
      }.to raise_error(R10K::Git::UnresolvableRefError)
    end

    it "looks up the ref against the linked repository" do
      subject.repository = repo
      expect(repo).to receive(:rev_parse).with(ref).and_return 'hash'
      expect(subject.sha1).to eq 'hash'
    end

    it "invokes the #ref method" do
      subject.repository = repo
      expect(repo).to receive(:rev_parse).with(ref).and_return 'hash'
      expect(subject).to receive(:ref).and_return ref
      expect(subject.sha1).to eq 'hash'
    end
  end

  it "can be converted to a string" do
    expect(subject.to_s).to eq ref
  end

  it_behaves_like "a git ref"
end
