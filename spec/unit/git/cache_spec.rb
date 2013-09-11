require 'spec_helper'

describe R10K::Git::Cache, 'memoizing objects' do

  it "wipes the memoized objects when .clear! is called" do
    first = described_class.new('foo')
    described_class.registry.clear!
    second = described_class.new('foo')

    first.should_not be second
  end
end

describe R10K::Git::Cache do

  describe 'setting the cache root' do
    it 'defaults to ~/.r10k/git' do
      expect(described_class.defaults[:cache_root]).to match %r[/\.r10k/git]
    end
  end
end
