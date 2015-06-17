require 'shared/puppet_forge/v3/module'

describe PuppetForge::V3::Module do
  subject { described_class.new('authorname-modulename') }

  let(:faraday_stubs) { Faraday::Adapter::Test::Stubs.new }

  let(:conn) do
    Faraday.new do |builder|
      builder.response(:raise_error)
      builder.adapter :test, faraday_stubs
    end
  end

  before do
    subject.conn = conn
  end

  let(:releases_without_deletions) do
      {"releases" => [
          {"version" => "1.0.1"},
          {"version" => "1.0.0"},
          {"version" => "0.9.0"}
        ]
      }
  end

  let(:releases_with_deletions) do
    {"releases" => [
        {"version" => "0.4.0", "deleted_at" => "some point"},
        {"version" => "0.3.0"}
      ]
    }
  end

  describe '#release' do
    it 'creates a release object for the module with the given version' do
      release = subject.release('3.1.4')
      expect(release.slug).to eq 'authorname-modulename-3.1.4'
    end

    it 'passes along the module connection object' do
      conn = Object.new
      subject.conn = conn
      release = subject.release('3.1.4')
      expect(release.conn).to eq conn
    end
  end

  describe '#versions' do
    it "returns all module release versions" do
      faraday_stubs.get('/v3/modules/authorname-modulename') { [200, {}, releases_without_deletions] }
      expect(subject.versions).to eq ["0.9.0", "1.0.0", "1.0.1"]
    end

    it "ignores deleted releases" do
      faraday_stubs.get('/v3/modules/authorname-modulename') { [200, {}, releases_with_deletions] }
      expect(subject.versions).to eq ["0.3.0"]
    end

    it "raises an error when the module does not exist" do
      faraday_stubs.get('/v3/modules/authorname-modulename') { [404, {}, ''] }
      expect {
        subject.versions
      }.to raise_error(PuppetForge::ModuleNotFound, /The module authorname-modulename does not exist/)
    end
  end

  describe '#latest_version' do
    it "returns the most recent version" do
      faraday_stubs.get('/v3/modules/authorname-modulename') { [200, {}, releases_without_deletions] }
      expect(subject.latest_version).to eq '1.0.1'
    end
  end
end
