require 'spec_helper'
require 'r10k/git'

describe R10K::Git::WorkingDir do

  describe "initializing" do
    it "generates a new cache for the remote" do
      wd = described_class.new('master', 'git://github.com/adrienthebo/r10k-fixture-repo', '/tmp')
      wd.cache.should be_kind_of R10K::Git::Cache
    end
  end
end
