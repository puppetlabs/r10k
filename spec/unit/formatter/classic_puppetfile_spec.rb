require 'spec_helper'
require 'r10k/formatter/classic_puppetfile'
require 'r10k/puppetfile'

describe R10K::Formatter::ClassicPuppetfile do

  let(:librarian) do
    R10K::Puppetfile.new(puppetfile_path)
  end

  let(:puppetfile_path) do
    File.join(puppetfile_fixtures, 'classic_format')
  end

  let(:formatter) do
    librarian.formatter
  end

  subject do
    formatter
  end

  it do
    expect(subject.load_content!).to be_a(Array)
  end

  it do
    expect(subject.load_content!.first).to be_a(R10K::Module::Forge)
  end

  it 'matches classic type with symbol' do
    expect(described_class.validate_formatter(File.join(puppetfile_path, 'Puppetfile'))).to be true
  end

  it 'does not match classic type' do
    expect(described_class.validate_formatter(File.join(puppetfile_path, 'Puppetfile_legacy'))).to be false
  end

  it 'matches classic type with string' do
    expect(described_class.validate_formatter(File.join(puppetfile_path, 'Puppetfile_legacy_string'))).to be true
  end


end