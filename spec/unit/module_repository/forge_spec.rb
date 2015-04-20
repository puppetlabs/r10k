require 'spec_helper'

require 'r10k/module_repository/forge'

describe R10K::ModuleRepository::Forge do

  it "uses the official forge by default" do
    forge = described_class.new('https://forgeapi.puppetlabs.com')
    expect(forge.forge).to eq 'https://forgeapi.puppetlabs.com'
  end

  it "replaces old forge with forgeapi" do
    forge = described_class.new(forge='forge.puppetlabs.com')
    expect(forge.forge).to eq 'https://forgeapi.puppetlabs.com'
  end

  it "can use a private forge" do
    forge = described_class.new('forge.example.local')
    expect(forge.forge).to eq 'forge.example.local'
  end

  describe "and the expected version is :latest", :vcr => true do
    subject(:forge) { described_class.new('https://forgeapi.puppetlabs.com') }

    before do
      forge.conn.builder.insert_before(Faraday::Adapter::NetHttp, VCR::Middleware::Faraday)
    end

    it "can fetch all versions of a given module" do
      expect(forge.versions('adrien/boolean')).to eq ["0.9.0-rc1", "0.9.0", "1.0.0", "1.0.1"]
    end

    it "can fetch the latest version of a given module" do
      expect(forge.latest_version('adrien/boolean')).to eq "1.0.1"
    end

    it "ignores deleted releases" do
      expect(forge.latest_version('r10ktesting/spotty')).to eq "0.3.0"
    end
  end

  describe "it handles errors from forgeapi.puppetlabs.com", :vcr => true do
    subject(:forge) { described_class.new('https://forgeapi.puppetlabs.com') }

    before do
      forge.conn.builder.insert_before(Faraday::Adapter::NetHttp, VCR::Middleware::Faraday)
    end

    it "raises an error for a non-existant module" do
      expect { forge.versions('dne/dne') }.to raise_error(R10K::Error)
    end
  end
end
