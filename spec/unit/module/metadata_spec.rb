require 'spec_helper'
require 'r10k/module/metadata'

describe R10K::Module::Metadata do

  let(:path) { double 'pathname' }

  subject(:metadata) { described_class.new(path) }

  it "defaults the version to R10K::SemVer::MIN" do
    expect(metadata.version).to eq R10K::SemVer::MIN
  end

  describe "determining if the metadata file exists" do
    it "doesn't exist if the given path isn't a file" do
      allow(path).to receive(:file?).and_return false
      expect(metadata).to_not be_exist
    end

    it "doesn't exist if the given path is an unreadable file" do
      allow(path).to receive(:file?).and_return true
      allow(path).to receive(:readable?).and_return false

      expect(metadata).to_not be_exist
    end

    it "exists if the given path exists and is readable" do
      allow(path).to receive(:file?).and_return true
      allow(path).to receive(:readable?).and_return true

      expect(metadata).to be_exist
    end
  end

  it "doesn't raise an error on invalid JSON" do
    allow(metadata).to receive(:exist?).and_return true
    allow(path).to receive(:read).and_return "Aha! You thought this was JSON!"

    metadata.read
  end

  describe "parsing a metadata file" do
    let(:json) do
      fixture_file = File.expand_path('spec/fixtures/module/forge/eight_hundred/metadata.json', PROJECT_ROOT)
      File.read(fixture_file)
    end

    before do
      allow(metadata).to receive(:exist?).and_return true
      allow(path).to receive(:read).and_return(json)

      metadata.read
    end

    it "extracts the module name" do
      expect(metadata.name).to eq 'eight_hundred'
    end

    it "extracts the module author" do
      expect(metadata.author).to eq 'branan'
    end

    it "extracts the module version" do
      expect(metadata.version).to be_a_kind_of R10K::SemVer
      expect(metadata.version).to eq R10K::SemVer.new('8.0.0')
    end
  end
end
