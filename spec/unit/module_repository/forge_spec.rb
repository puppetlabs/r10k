require 'spec_helper'

require 'faraday'

require 'r10k/module_repository/forge'

describe R10K::ModuleRepository::Forge do

  let(:faraday_stubs) { Faraday::Adapter::Test::Stubs.new }

  let(:conn) do
    Faraday.new { |builder| builder.adapter(:test, faraday_stubs) }
  end

  before do
    allow_any_instance_of(described_class).to receive(:make_conn).and_return conn
  end

  it "uses the official forge by default" do
    forge = described_class.new
    expect(forge.forge).to eq 'forgeapi.puppetlabs.com'
  end

  it "replaces old forge with forgeapi" do
    forge = described_class.new(forge='forge.puppetlabs.com')
    expect(forge.forge).to eq 'forgeapi.puppetlabs.com'
  end

  it "can use a private forge" do
    forge = described_class.new('forge.example.local')
    expect(forge.forge).to eq 'forge.example.local'
  end

  describe "and the expected version is :latest" do
    subject(:forge) { described_class.new }

    let(:boolean_body) do
        {"releases" => [
            {"version" => "1.0.1"},
            {"version" => "1.0.0"},
            {"version" => "0.9.0"}
          ]
        }
    end

    let(:spotty_body) do
      {"releases" => [
          {"version" => "0.4.0", "deleted_at" => "some point"},
          {"version" => "0.3.0"}
        ]
      }
    end

    before do
      faraday_stubs.get('/v3/modules/adrien-boolean') { [200, {}, boolean_body] }
      faraday_stubs.get('/v3/modules/r10ktesting-spotty') { [200, {}, spotty_body] }
    end

    it "can fetch all versions of a given module" do
      expect(forge.versions('adrien/boolean')).to eq ["0.9.0", "1.0.0", "1.0.1"]
    end

    it "can fetch the latest version of a given module" do
      expect(forge.latest_version('adrien/boolean')).to eq "1.0.1"
    end

    it "ignores deleted releases" do
      expect(forge.latest_version('r10ktesting/spotty')).to eq "0.3.0"
    end
  end

  describe "it handles errors from forgeapi.puppetlabs.com" do
    subject(:forge) { described_class.new }

    before do
      faraday_stubs.get('/v3/modules/dne-dne') { [404, {}, 'not found'] }
    end

    it "raises an error for a non-existant module" do
      expect { forge.versions('dne/dne') }.to raise_error(R10K::Error)
    end
  end
end
