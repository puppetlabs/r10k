require 'spec_helper'
require 'r10k/tarball'

describe R10K::Tarball do
  include_context 'Tarball'

  subject { described_class.new('fixture-tarball', fixture_tarball, checksum: fixture_checksum) }

  describe 'initialization' do
    it 'initializes' do
      expect(subject).to be_kind_of(described_class)
    end
  end

  describe 'downloading and caching' do
    it 'downloads the source to the cache' do
      # No cache present initially
      expect(File.exist?(subject.cache_path)).to be(false)
      expect(subject.cache_valid?).to be(false)

      subject.get

      expect(subject.cache_valid?).to be(true)
      expect(File.exist?(subject.cache_path)).to be(true)
    end

    let(:raw_content) {[
      './',
      './Puppetfile',
      './metadata.json',
      './spec/',
      './environment.conf',
      './spec/1',
    ]}

    let(:clean_content) {[
      'Puppetfile',
      'metadata.json',
      'spec',
      'environment.conf',
      'spec/1',
    ]}

    it 'returns clean paths when listing cached tarball content' do
      iterator = allow(subject).to receive(:each_tarball_entry)
      raw_content.each { |entry| iterator.and_yield(entry) }

      expect(subject.paths).to eq(clean_content)
    end
  end

  describe 'http sources'

  describe 'file sources'

  describe 'syncing'
end
