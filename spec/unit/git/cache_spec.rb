require 'spec_helper'

describe R10K::Git::Cache, 'memoizing objects' do

  it "returns the same object when a remote is duplicated" do
    first  = described_class.new('foo')
    second = described_class.new('foo')

    first.should be second
  end

  it "wipes the memoized objects when .clear! is called" do
    first = described_class.new('foo')
    described_class.clear!
    second = described_class.new('foo')

    first.should_not be second
  end
end

describe R10K::Git::Cache do

  after do
    described_class.clear!
  end

  describe 'setting the cache root' do
    it 'defaults to ~/.r10k/git' do
      expect(described_class.defaults[:cache_root]).to match %r[/\.r10k/git]
    end
  end
end
