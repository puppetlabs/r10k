require 'spec_helper'
require 'r10k/environment'

describe R10K::Environment::Tarball do
  let(:tgz_path) do
    File.expand_path('spec/fixtures/tarball/tarball.tar.gz', PROJECT_ROOT)
  end

  let(:checksum) { '36afcfc2378b8235902d6e647fce7479da6898354d620388646c595a1155ed67' }
  let(:base_params) { { source: tgz_path, version: checksum, modules: { } } }

  subject { described_class.new('envname', '/some/imaginary/path', 'dirname', base_params) }

  describe "initializing" do
    it "accepts valid base class initialization arguments" do
      expect(subject.name).to eq 'envname'
    end
  end

  describe "storing attributes" do
    it "can return the environment name" do
      expect(subject.name).to eq 'envname'
    end

    it "can return the environment basedir" do
      expect(subject.basedir).to eq '/some/imaginary/path'
    end

    it "can return the environment dirname" do
      expect(subject.dirname).to eq 'dirname'
    end

    it "can return the environment path" do
      expect(subject.path.to_s).to eq '/some/imaginary/path/dirname'
    end

    it "can return the environment source" do
      expect(subject.tarball.source).to eq tgz_path
    end

    it "can return the environment version" do
      expect(subject.tarball.checksum).to eq checksum
    end
  end
end
