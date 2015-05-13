require 'spec_helper'
require 'r10k/forge/module_release'

describe R10K::Forge::ModuleRelease do
  subject { described_class.new('branan-eight_hundred', '8.0.0') }

  let(:download_path) { instance_double('Pathname') }
  let(:unpack_path) { instance_double('Pathname') }

  let(:target_dir) { instance_double('Pathname') }

  before do
    subject.download_path = download_path
    subject.unpack_path = unpack_path
  end

  describe '#download' do
    it "downloads the module from the forge into `download_path`" do
      expect(subject.forge_release).to receive(:download).with(download_path)
      subject.download
    end
  end

  describe '#verify' do
    it "verifies the module checksum based on the Forge file checksum" do
      expect(subject.forge_release).to receive(:verify).with(download_path)
      subject.verify
    end
  end

  describe '#unpack' do
    it "unpacks the module tarball in `download_path` into the provided target path" do
      expect(PuppetForge::Unpacker).to receive(:unpack).with(download_path.to_s, target_dir.to_s, unpack_path.to_s)
      subject.unpack(target_dir)
    end
  end

  describe "#cleanup" do
    it "cleans up the download and unpack paths" do
      expect(subject).to receive(:cleanup_unpack_path)
      expect(subject).to receive(:cleanup_download_path)
      subject.cleanup
    end
  end

  describe "#cleanup_unpack_path" do
    it "ignores the unpack_path if it doesn't exist" do
      expect(unpack_path).to receive(:exist?).and_return false
      expect(unpack_path).to_not receive(:rmtree)
      subject.cleanup_unpack_path
    end

    it "removes the unpack_path if it exists" do
      expect(unpack_path).to receive(:exist?).and_return true
      expect(unpack_path).to receive(:rmtree)
      subject.cleanup_unpack_path
    end
  end

  describe "#cleanup_download_path" do
    it "ignores the download_path if it doesn't exist" do
      expect(download_path).to receive(:exist?).and_return false
      expect(download_path).to_not receive(:delete)
      subject.cleanup_download_path
    end

    it "removes the download_path if it exists" do
      expect(download_path).to receive(:exist?).and_return true
      expect(download_path).to receive(:delete)
      subject.cleanup_download_path
    end
  end

  describe '#install' do
    it "performs all steps needed to install the module" do
      expect(subject).to receive(:download)
      expect(subject).to receive(:verify)
      expect(subject).to receive(:unpack).with(target_dir)
      expect(subject).to receive(:cleanup)
      subject.install(target_dir)
    end
  end
end
