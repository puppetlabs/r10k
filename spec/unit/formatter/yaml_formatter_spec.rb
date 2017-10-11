require 'spec_helper'
require 'r10k/formatter/yaml_formatter'
require 'r10k/puppetfile'

describe R10K::Formatter::YamlFormatter do

  let(:librarian) do
    R10K::Puppetfile.new(File.join(puppetfile_fixtures, 'yaml_format'),
                         nil, librarian_file_path,
                         'Puppetfile.yaml')
  end

  let(:librarian_file_path) do
    File.join(puppetfile_fixtures, 'yaml_format', 'Puppetfile.yaml')
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

  it do
    expect(described_class.validate_formatter(librarian_file_path)).to be true
  end

  it 'does match yaml type' do
    expect(described_class.validate_formatter(File.join(puppetfile_fixtures, 'yaml_format', 'Puppetfile.yaml'))).to be true
  end

  it 'does not match yaml type' do
    expect(described_class.validate_formatter(File.join(puppetfile_fixtures, 'yaml_format', 'Puppetfile_no_type.yaml'))).to be false
  end

end
