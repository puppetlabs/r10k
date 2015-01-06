require 'spec_helper'
require 'r10k/git/cache'

describe R10K::Git::Cache do

  subject(:cache) { described_class.new('git://some/git/remote') }

  describe "updating the cache" do
    it "only updates the cache once" do
      expect(cache).to receive(:sync!).exactly(1).times
      cache.sync
      cache.sync
    end
  end

  describe "methods on the repository" do
    def expect_delegation(method)
      expect(subject.repo).to receive(method)
      subject.send(method)
    end

    it "delegates #git_dir" do
      expect_delegation(:git_dir)
    end

    it "delegates #branches" do
      expect_delegation(:branches)
    end

    it "delegates #tags" do
      expect_delegation(:tags)
    end

    it "delegates #exist?" do
      expect_delegation(:exist?)
    end

    it "aliases #cached? to #exist?" do
      expect(subject.repo).to receive(:exist?)
      subject.cached?
    end
  end
end
