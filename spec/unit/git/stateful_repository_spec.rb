require 'spec_helper'
require 'r10k/git'
require 'r10k/git/stateful_repository'

describe R10K::Git::StatefulRepository do

  let(:remote) { 'git://some.site/some-repo.git' }
  let(:ref) { '0.9.x' }

  subject { described_class.new(remote, '/some/nonexistent/basedir', 'some-dirname') }

  describe "determining if the cache needs to be synced" do
    let(:cache) { double('cache') }

    before { expect(R10K::Git.cache).to receive(:generate).with(remote).and_return(cache) }

    it "is true if the cache is absent" do
      expect(cache).to receive(:exist?).and_return false
      expect(subject.sync_cache?(ref)).to eq true
    end

    it "is true if the ref is unresolvable" do
      expect(cache).to receive(:exist?).and_return true
      expect(cache).to receive(:resolve).with('0.9.x')
      expect(subject.sync_cache?(ref)).to eq true
    end

    it "is true if the ref is not a tag or commit" do
      expect(cache).to receive(:exist?).and_return true
      expect(cache).to receive(:resolve).with('0.9.x').and_return('93456ec7dc0f6fd3ac193b4df64f6544615dfbc9')
      expect(cache).to receive(:ref_type).with('0.9.x').and_return(:branch)
      expect(subject.sync_cache?(ref)).to eq true
    end

    it "is false otherwise" do
      expect(cache).to receive(:exist?).and_return true
      expect(cache).to receive(:resolve).with('0.9.x').and_return('93456ec7dc0f6fd3ac193b4df64f6544615dfbc9')
      expect(cache).to receive(:ref_type).with('0.9.x').and_return(:tag)
      expect(subject.sync_cache?(ref)).to eq false
    end

  end
end
