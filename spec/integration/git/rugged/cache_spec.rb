require 'spec_helper'
require 'r10k/git/rugged/cache'

describe R10K::Git::Rugged::Cache, :if => R10K::Features.available?(:rugged) do
  include_context 'Git integration'

  let(:dirname) { 'working-repo' }
  let(:remote_name) { 'origin' }

  subject { described_class.new(remote) }

  context "syncing with the remote" do
    before(:each) do
      subject.reset!
    end

    describe "with the correct configuration" do
      it "is able to sync with the remote" do
        subject.sync
        expect(subject.synced?).to eq(true)
      end
    end

    describe "with a out of date cached remote" do
      it "updates the cached remote configuration" do
        subject.repo.update_remote('foo', remote_name)
        expect(subject.repo.remotes[remote_name]).to eq('foo')
        subject.sync
        expect(subject.repo.remotes[remote_name]).to eq(remote)
      end
    end
  end
end
