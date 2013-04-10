require 'spec_helper'

describe R10K::Git::WorkingDir do

  before do
    R10K::Git::Cache.stubs(:cache_root).returns '/tmp'
  end

  describe "initializing" do
    it "generates a new cache for the remote" do
      wd = described_class.new('foo')
      wd.cache.should be_kind_of R10K::Git::Cache
    end
  end
end
