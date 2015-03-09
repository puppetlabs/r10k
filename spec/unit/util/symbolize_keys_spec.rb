require 'spec_helper'
require 'r10k/util/symbolize_keys'

describe R10K::Util::SymbolizeKeys do
  it "deletes all keys that are strings" do
    hash = {'foo' => 'bar', :baz => 'quux'}
    described_class.symbolize_keys!(hash)
    expect(hash).to_not have_key('foo')
  end

  it "replaces the deleted keys with interned strings" do
    hash = {'foo' => 'bar', :baz => 'quux'}

    described_class.symbolize_keys!(hash)
    expect(hash[:foo]).to eq 'bar'
  end

  it "raises an error if there is an existing symbol for a given string key" do
    hash = {'foo' => 'bar', :foo => 'quux'}

    expect {
      described_class.symbolize_keys!(hash)
    }.to raise_error(TypeError, /An existing interned key/)
  end

  it "does not modify existing symbol entries" do
    hash = {'foo' => 'bar', :baz => 'quux'}

    described_class.symbolize_keys!(hash)
    expect(hash[:baz]).to eq 'quux'
  end

  it "does not modify keys that are not strings or symbols" do
    key = %w[foo]
    hash = {key => 'bar', :baz => 'quux'}
    described_class.symbolize_keys!(hash)
    expect(hash[key]).to eq 'bar'
  end
end
