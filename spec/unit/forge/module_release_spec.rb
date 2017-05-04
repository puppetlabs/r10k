require 'spec_helper'
require 'r10k/forge/module_release'
require 'r10k/util/exec_env'
require 'puppet_forge'

describe R10K::Forge::ModuleRelease do
  subject { described_class.new('branan-eight_hundred', '8.0.0') }

  let(:forge_release_class) { PuppetForge::V3::Release }

  let(:download_path) { instance_double('Pathname') }
  let(:tarball_cache_path) { instance_double('Pathname') }
  let(:tarball_cache_root) { instance_double('Pathname') }
  let(:unpack_path) { instance_double('Pathname') }
  let(:target_dir) { instance_double('Pathname') }
  let(:file_lists) { {:valid=>['valid_ex'], :invalid=>[], :symlinks=>['symlink_ex']} }

  before do
    subject.download_path = download_path
    subject.tarball_cache_path = tarball_cache_path
    subject.tarball_cache_root = tarball_cache_root
    subject.unpack_path = unpack_path
  end

  context "no cached tarball" do
    describe '#download' do
      it "downloads the module from the forge into `download_path`" do
        expect(tarball_cache_path).to receive(:exist?).and_return(false)
        expect(subject.forge_release).to receive(:download).with(download_path)
        allow(FileUtils).to receive(:mkdir_p).with(tarball_cache_root)
        expect(FileUtils).to receive(:mv).with(download_path, tarball_cache_path)
        subject.download
      end
    end
  end

  context "with cached tarball" do
    describe '#download' do
      it "does not download a new tarball" do
        expect(tarball_cache_path).to receive(:exist?).and_return(true)
        expect(subject.forge_release).not_to receive(:download).with(download_path)
        subject.download
      end
    end
  end

  describe '#verify' do
    it "verifies the module checksum based on the Forge file checksum" do
      allow(subject.forge_release).to receive(:file_md5).and_return('something')
      expect(subject.forge_release).to receive(:verify).with(tarball_cache_path)
      subject.verify
    end

    it "removes the cached tarball and passes on a checksum error" do
      allow(subject.forge_release).to receive(:file_md5).and_return('something')
      expect(subject.forge_release).to receive(:verify).with(tarball_cache_path).and_raise(PuppetForge::V3::Release::ChecksumMismatch)
      expect(subject).to receive(:cleanup_cached_tarball_path)
      expect{ subject.verify }.to raise_error(PuppetForge::V3::Release::ChecksumMismatch)
    end
  end

  describe '#unpack' do
    it "unpacks the module tarball in `tarball_cache_path` into the provided target path" do
      expect(PuppetForge::Unpacker).to receive(:unpack).with(tarball_cache_path.to_s, target_dir.to_s, unpack_path.to_s).\
          and_return({:valid=>["extractedmodule/metadata.json"], :invalid=>[], :symlinks=>[]})
      subject.unpack(target_dir)
    end

    it "logs a warning if symlinks are present during the unpacking process" do
      logger_dbl = double(Log4r::Logger, debug1: true, debug2: true)
      allow(subject).to receive(:logger).and_return(logger_dbl)
      allow(PuppetForge::Unpacker).to receive(:unpack).and_return(file_lists)

      expect(logger_dbl).to receive(:warn).with(/symlinks are unsupported.*#{Regexp.escape(subject.forge_release.slug)}/i)

      subject.unpack(target_dir)
    end
  end

  describe "#cleanup" do
    it "cleans up the unpack paths" do
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
