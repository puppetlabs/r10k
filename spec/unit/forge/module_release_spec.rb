require 'spec_helper'
require 'r10k/forge/module_release'
require 'r10k/util/exec_env'
require 'puppet_forge'

describe R10K::Forge::ModuleRelease do
  subject { described_class.new('branan-eight_hundred', '8.0.0') }

  let(:forge_release_class) { PuppetForge::V3::Release }
  let(:sha256_digest_class) { Digest::SHA256 }
  let(:md5_digest_class) { Digest::MD5 }

  let(:download_path) { instance_double('Pathname') }
  let(:tarball_cache_path) { instance_double('Pathname') }
  let(:tarball_cache_root) { instance_double('Pathname') }
  let(:unpack_path) { instance_double('Pathname') }
  let(:target_dir) { instance_double('Pathname') }
  let(:tarball_cache_path) { instance_double('Pathname') }
  let(:md5_file_path) { instance_double('Pathname') }
  let(:sha256_file_path) { instance_double('Pathname') }

  let(:file_lists) { {:valid=>['valid_ex'], :invalid=>[], :symlinks=>['symlink_ex']} }

  let(:file_contents) { "skeletor's closet" }
  let(:sha256_digest) { instance_double('Digest::SHA256') }
  let(:sha256_of_tarball) { "sha256_hash" }
  let(:md5_digest) { instance_double('Digest::MD5') }
  let(:md5_of_tarball) { "md5_hash" }
  let(:good_md5) { md5_of_tarball }
  let(:good_sha256) { sha256_of_tarball }
  let(:bad_sha256) { "bad_sha256_hash" }
  let(:bad_md5) { "bad_md5_hash" }

  before do
    subject.download_path = download_path
    subject.tarball_cache_path = tarball_cache_path
    subject.tarball_cache_root = tarball_cache_root
    subject.unpack_path = unpack_path
    subject.md5_file_path = md5_file_path
    subject.sha256_file_path = sha256_file_path
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

    it "verifies using the file SHA256, if that exists" do
      allow(sha256_digest_class).to receive(:file).and_return(sha256_digest)
      allow(sha256_digest).to receive(:hexdigest).and_return(sha256_of_tarball)
      allow(sha256_file_path).to receive(:exist?).and_return(true)
      expect(subject).to receive(:verify_from_file).with(sha256_of_tarball, sha256_file_path)
      subject.verify
    end

    it "verifies using the forge file_sha256, if no sha256 file exists" do
      allow(sha256_digest_class).to receive(:file).and_return(sha256_digest)
      allow(sha256_digest).to receive(:hexdigest).and_return(sha256_of_tarball)
      allow(sha256_file_path).to receive(:exist?).and_return(false)
      allow(subject.forge_release).to receive(:respond_to?).and_return(true)
      allow(subject.forge_release).to receive(:sha256_file).and_return(sha256_of_tarball)
      expect(subject).to receive(:verify_from_forge)
      subject.verify
    end

    it "falls back to md5 verification when not in FIPS mode and no sha256 available" do
      expect(R10K::Util::Platform).to receive(:fips?).and_return(false)
      # failed sha256 verification
      allow(sha256_digest_class).to receive(:file).and_return(sha256_digest)
      allow(sha256_digest).to receive(:hexdigest).and_return(sha256_of_tarball)
      allow(sha256_file_path).to receive(:exist?).and_return(false)
      allow(subject.forge_release).to receive(:respond_to?).and_return(false)
      allow(subject).to receive(:verify_from_forge)
      # md5 verification
      allow(md5_digest_class).to receive(:file).and_return(md5_digest)
      allow(md5_digest).to receive(:hexdigest).and_return(md5_of_tarball)
      allow(md5_file_path).to receive(:exist?).and_return(true)
      expect(subject).to receive(:verify_from_file)
      subject.verify
    end

    it "errors when in FIPS mode and no sha256 is available" do
      expect(R10K::Util::Platform).to receive(:fips?).and_return(true)
      allow(sha256_digest_class).to receive(:file).and_return(sha256_digest)
      allow(sha256_digest).to receive(:hexdigest).and_return(sha256_of_tarball)
      allow(sha256_file_path).to receive(:exist?).and_return(false)
      allow(subject.forge_release).to receive(:respond_to?).and_return(false)
      allow(subject).to receive(:verify_from_forge)
      expect { subject.verify }.to raise_error(R10K::Error)
    end
  end

  describe '#verify_from_file' do

    it "does nothing when the checksums match" do
      expect(File).to receive(:read).with(sha256_file_path).and_return(good_sha256)
      expect(subject).not_to receive(:cleanup_cached_tarball_path)
      subject.verify_from_file(sha256_of_tarball, sha256_file_path)
    end

    it "raises an error and cleans up when the checksums do not match" do
      expect(File).to receive(:read).with(sha256_file_path).and_return(bad_sha256)
      expect(tarball_cache_path).to receive(:delete)
      expect(sha256_file_path).to receive(:delete)
      expect { subject.verify_from_file(sha256_of_tarball, sha256_file_path) }.to raise_error(PuppetForge::V3::Release::ChecksumMismatch)
    end
  end

  describe '#verify_from_forge' do
    it "write the checksum to file when the checksums match" do
      expect(tarball_cache_path).not_to receive(:delete)
      expect(File).to receive(:write).with(sha256_file_path, good_sha256)
      subject.verify_from_forge(sha256_of_tarball, good_sha256, sha256_file_path)
    end

    it "raises an error and cleans up when the checksums do not match" do
      expect(tarball_cache_path).to receive(:delete)
      expect { subject.verify_from_forge(sha256_of_tarball, bad_sha256, sha256_file_path) }
        .to raise_error(PuppetForge::V3::Release::ChecksumMismatch)
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
      expect(unpack_path).to_not receive(:parent)
      subject.cleanup_unpack_path
    end

    it "removes the containing directory of unpack_path if it exists" do
      parent = instance_double('Pathname')
      expect(parent).to receive(:rmtree)
      expect(unpack_path).to receive(:exist?).and_return true
      expect(unpack_path).to receive(:parent).and_return(parent)
      subject.cleanup_unpack_path
    end
  end

  describe "#cleanup_download_path" do
    it "ignores the download_path if it doesn't exist" do
      expect(download_path).to receive(:exist?).and_return false
      expect(download_path).to_not receive(:parent)
      subject.cleanup_download_path
    end

    it "removes the containing directory of download_path if it exists" do
      parent = instance_double('Pathname')
      expect(parent).to receive(:rmtree)
      expect(download_path).to receive(:exist?).and_return true
      expect(download_path).to receive(:parent).and_return(parent)
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
