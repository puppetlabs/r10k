require 'spec_helper'
require 'r10k/plugin_loader'

describe R10K::PluginLoader do
  include R10K::PluginLoader

  let(:puppetfile) do
    File.join(puppetfile_fixtures, 'valid-forge-without-version', 'Puppetfile')
  end

  it do
    expect(formatter_path).to eq('lib/r10k/formatter')
  end

  it do
    expect(load_plugins).to include("lib/r10k/formatter/base_formatter.rb")
    expect(load_plugins).to include("lib/r10k/formatter/classic_puppetfile.rb")
  end

  it do
    expect(gem_directories).to eq(["lib/r10k/formatter"])
  end

  it do
    expect(r10k_formatter_gem_list).to eq(["lib/r10k/formatter"])
  end

  it 'raise NoFormatter error' do
    expect{first_formatter(puppetfile)}.to raise_error(R10K::NoFormatterError)
  end

  it 'find classic formatter' do
    expect(first_formatter(File.join(puppetfile_fixtures, 'classic_format', 'Puppetfile_legacy_string')))
        .to eq(R10K::Formatter::ClassicPuppetfile)
  end

end