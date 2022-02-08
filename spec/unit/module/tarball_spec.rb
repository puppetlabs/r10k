require 'spec_helper'
require 'r10k/module'
require 'fileutils'

describe R10K::Module::Tarball do
  include_context 'Tarball'

  let(:base_params) { { type: 'tarball', source: fixture_tarball, version: fixture_checksum } }

  subject do
    described_class.new(
      'fixture-tarball',
      moduledir,
      base_params,
    )
  end

  describe "setting the owner and name" do
    describe "with a title of 'fixture-tarball'" do
      it "sets the owner to 'fixture'" do
        expect(subject.owner).to eq 'fixture'
      end

      it "sets the name to 'tarball'" do
        expect(subject.name).to eq 'tarball'
      end

      it "sets the path to the given moduledir + modname" do
        expect(subject.path.to_s).to eq(File.join(moduledir, 'tarball'))
      end
    end
  end

  describe "properties" do
    it "sets the module type to :tarball" do
      expect(subject.properties).to include(type: :tarball)
    end

    it "sets the version" do
      expect(subject.properties).to include(expected: fixture_checksum)
    end
  end

  describe 'syncing the module' do
    it 'defaults to deleting the spec dir' do
      subject.sync
      expect(Dir.exist?(File.join(moduledir, 'tarball', 'spec'))).to be(false)
    end
  end

  describe "determining the status" do
    it "delegates to R10K::Tarball" do
      expect(subject).to receive(:tarball).twice.and_return instance_double('R10K::Tarball', cache_valid?: true, insync?: true)
      expect(subject).to receive(:path).twice.and_return instance_double('Pathname', exist?: true)

      expect(subject.status).to eq(:insync)
    end
  end

  describe "option parsing" do
    describe "version" do
      context "when no version is given" do
        subject { described_class.new('fixture-tarball', moduledir, base_params.reject { |k| k.eql?(:version) }) }
        it "does not require a version" do
          expect(subject).to be_kind_of(described_class)
        end
      end
    end
  end
end
