require 'spec_helper'

describe R10K::Git::Rugged::Cache, :unless => R10K::Util::Platform.jruby? do
  before(:all) do
    require 'r10k/git/rugged/cache'
  end

  subject(:cache) { described_class.new('https://some/git/remote') }

  it "wraps a Rugged::BareRepository instance" do
    expect(cache.repo).to be_a_kind_of R10K::Git::Rugged::BareRepository
  end

  describe "settings" do
    before do
      R10K::Git::Cache.settings[:cache_root] = '/some/path'
      described_class.settings.reset!
    end

    after do
      R10K::Git::Cache.settings.reset!
      described_class.settings.reset!
    end

    it "falls back to the parent class settings" do
      expect(described_class.settings[:cache_root]).to eq '/some/path'
    end
  end

  describe "remote url updates" do
    before do
      allow(subject.repo).to receive(:exist?).and_return true
      allow(subject.repo).to receive(:fetch)
      allow(subject.repo).to receive(:remotes).and_return({ 'origin' => 'https://some/git/remote' })
    end

    it "does not update the URLs if they match" do
      expect(subject.repo).to_not receive(:update_remote)
      subject.sync!
    end

    it "updates the remote URL if they do not match" do
      allow(subject.repo).to receive(:remotes).and_return({ 'origin' => 'foo'})
      expect(subject.repo).to receive(:update_remote)
      subject.sync!
    end
  end
end
