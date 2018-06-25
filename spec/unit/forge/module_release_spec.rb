require 'spec_helper'
require 'r10k/forge/module_release'
require 'r10k/util/exec_env'
require 'puppet_forge'

describe R10K::Forge::ModuleRelease do
  subject { described_class.new('branan-eight_hundred', '8.0.0') }

  let(:forge_release_class) { PuppetForge::V3::Release }
  let(:md5_digest_class) { Digest::MD5 }

  let(:download_path) { instance_double('Pathname') }
  let(:download_root) { instance_double('Pathname') }
  let(:tarball_cache_path) { instance_double('Pathname') }
  let(:tarball_cache_root) { instance_double('Pathname') }
  let(:unpack_path) { instance_double('Pathname') }
  let(:unpack_root) { instance_double('Pathname') }
  let(:target_dir) { instance_double('Pathname') }
  let(:md5_file_path) { instance_double('Pathname') }

  let(:file_lists) { {:valid=>['valid_ex'], :invalid=>[], :symlinks=>['symlink_ex']} }

  let(:file_contents) { "skeletor's closet" }
  let(:md5_of_tarball) { "something_hexy" }
  let(:good_md5) { md5_of_tarball }
  let(:bad_md5) { "different_hexy_thing" }

  before do
    subject.download_path = download_path
    subject.download_root = download_root
    subject.tarball_cache_path = tarball_cache_path
    subject.tarball_cache_root = tarball_cache_root
    subject.unpack_path = unpack_path
    subject.unpack_root = unpack_root
    subject.md5_file_path = md5_file_path
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

    it "verifies using the file md5, if that exists" do
      allow(File).to receive(:read).and_return(file_contents)
      allow(md5_digest_class).to receive(:hexdigest).and_return(md5_of_tarball)
      allow(md5_file_path).to receive(:exist?).and_return(true)
      expect(subject).to receive(:verify_from_md5_file).with(md5_of_tarball)
      subject.verify
    end

    it "verifies using the forge file_md5, if no md5 file exists" do
      allow(File).to receive(:read).and_return(file_contents)
      allow(md5_digest_class).to receive(:hexdigest).and_return(md5_of_tarball)
      allow(md5_file_path).to receive(:exist?).and_return(false)
      expect(subject).to receive(:verify_from_forge).with(md5_of_tarball)
      subject.verify
    end
  end

  describe '#verify_from_md5_file' do

    it "does nothing when the checksums match" do
      expect(File).to receive(:read).with(md5_file_path).and_return(good_md5)
      expect(subject).not_to receive(:cleanup_cached_tarball_path)
      subject.verify_from_md5_file(md5_of_tarball)
    end

    it "raises an error and cleans up when the checksums do not match" do
      expect(File).to receive(:read).with(md5_file_path).and_return(bad_md5)
      expect(subject).to receive(:cleanup_cached_tarball_path)
      expect(subject).to receive(:cleanup_md5_file_path)
      expect { subject.verify_from_md5_file(md5_of_tarball) }.to raise_error(PuppetForge::V3::Release::ChecksumMismatch)
    end
  end

  describe '#verify_from_forge' do
    it "write the md5 to file when the checksums match" do
      expect(subject.forge_release).to receive(:file_md5).and_return(good_md5)
      expect(subject).not_to receive(:cleanup_cached_tarball_path)
      expect(File).to receive(:write).with(md5_file_path, good_md5)
      subject.verify_from_forge(md5_of_tarball)
    end

    it "raises an error and cleans up when the checksums do not match" do
      expect(subject.forge_release).to receive(:file_md5).and_return(bad_md5)
      expect(subject).to receive(:cleanup_cached_tarball_path)
      expect { subject.verify_from_forge(md5_of_tarball) }.to raise_error(PuppetForge::V3::Release::ChecksumMismatch)
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
      expect(subject).to receive(:cleanup_unpack_root)
      expect(subject).to receive(:cleanup_download_root)
      subject.cleanup
    end
  end

  describe "#cleanup_unpack_root" do
    it "ignores the unpack_root if it doesn't exist" do
      expect(unpack_root).to receive(:exist?).and_return false
      expect(unpack_root).to_not receive(:rmtree)
      subject.cleanup_unpack_root
    end

    it "removes the unpack_root if it exists" do
      expect(unpack_root).to receive(:exist?).and_return true
      expect(unpack_root).to receive(:rmtree)
      subject.cleanup_unpack_root
    end
  end

  describe "#cleanup_download_root" do
    it "ignores the download_root if it doesn't exist" do
      expect(download_root).to receive(:exist?).and_return false
      expect(download_root).to_not receive(:rmtree)
      subject.cleanup_download_root
    end

    it "removes the download_root if it exists" do
      expect(download_root).to receive(:exist?).and_return true
      expect(download_root).to receive(:rmtree)
      subject.cleanup_download_root
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
