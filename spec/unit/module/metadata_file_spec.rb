require 'spec_helper'

describe R10K::Module::MetadataFile do

  let(:path) { double 'pathname' }

  subject(:metadata_file) { described_class.new(path) }

  describe "determining if the metadata file exists" do
    it "doesn't exist if the given path isn't a file" do
      allow(path).to receive(:file?).and_return false
      expect(metadata_file).to_not be_exist
    end

    it "doesn't exist if the given path is an unreadable file" do
      allow(path).to receive(:file?).and_return true
      allow(path).to receive(:readable?).and_return false

      expect(metadata_file).to_not be_exist
    end

    it "exists if the given path exists and is readable" do
      allow(path).to receive(:file?).and_return true
      allow(path).to receive(:readable?).and_return true

      expect(metadata_file).to be_exist
    end
  end

  describe "parsing a metadata file" do
    let(:fixture_path) do
      fixture_path = Pathname.new(File.expand_path('spec/fixtures/module/forge/eight_hundred/metadata.json', PROJECT_ROOT))
    end

    before do
      a_metadata_file = R10K::Module::MetadataFile.new(fixture_path)
      @metadata = a_metadata_file.read
    end

    it "extracts the module name" do
      expect(@metadata.name).to eq 'eight_hundred'
    end

    it "extracts the full module name" do
      expect(@metadata.full_module_name).to eq 'branan-eight_hundred'
    end

    it "extracts the module author" do
      expect(@metadata.author).to eq 'Branan Purvine-Riley'
    end

    it "extracts the module version" do
      expect(@metadata.version).to eq '8.0.0'
    end
  end

  describe "parsing an invalid metadata file" do
    let(:fixture_path) do
      fixture_path = Pathname.new(File.expand_path('spec/fixtures/module/forge/bad_module/metadata.json', PROJECT_ROOT))
    end

    it "raises an error" do
      a_metadata_file = R10K::Module::MetadataFile.new(fixture_path)
      expect {a_metadata_file.read}.to raise_error(R10K::Error, "Could not read metadata.json")
    end
  end

end
