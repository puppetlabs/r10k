require 'r10k/logging'
require 'r10k/settings/mixin'
require 'fileutils'
require 'tmpdir'
require 'puppet_forge'

module R10K
  module Forge
    # Download, unpack, and install modules from the Puppet Forge
    class ModuleRelease

      include R10K::Settings::Mixin

      def_setting_attr :proxy
      def_setting_attr :baseurl
      def_setting_attr :cache_root, File.expand_path(ENV['HOME'] ? '~/.r10k/cache': '/root/.r10k/cache')

      include R10K::Logging

      # @!attribute [r] forge_release
      #   @api private
      #   @return [PuppetForge::V3::ModuleRelease] The Forge V3 API module
      #     release object used for downloading and verifying the module
      #     release.
      attr_reader :forge_release

      # @!attribute [rw] download_path
      #   @return [Pathname] Where the module tarball will be downloaded to.
      attr_accessor :download_path

      # @!attribute [rw] tarball_cache_path
      #   @return [Pathname] Where the module tarball will be cached to.
      attr_accessor :tarball_cache_path

      # @!attribute [rw] tarball_cache_root
      #   @return [Pathname] Directory where the module tarball will be cached to.
      attr_accessor :tarball_cache_root

      # @!attribute [rw] md5_file_path
      #   @return [Pathname] Where the md5 of the cached tarball is stored.
      attr_accessor :md5_file_path

      # @!attribute [rw] sha256_file_path
      #   @return [Pathname] Where the SHA256 of the cached tarball is stored.
      attr_accessor :sha256_file_path

      # @!attribute [rw] unpack_path
      #   @return [Pathname] Where the module will be unpacked to.
      attr_accessor :unpack_path

      # @param full_name [String] The hyphen separated name of the module
      # @param version [String] The version of the module
      def initialize(full_name, version)
        @full_name = PuppetForge::V3.normalize_name(full_name)
        @version   = version

        # Copy the PuppetForge base connection to the release class; the connection
        # objects are created in the class instances and thus are not shared with
        # subclasses.
        PuppetForge::V3::Release.conn = PuppetForge::V3::Base.conn

        @forge_release = PuppetForge::V3::Release.new({ :name => @full_name, :version => @version, :slug => "#{@full_name}-#{@version}" })

        tarball_name = @forge_release.slug + '.tar.gz'
        @download_path = Pathname.new(Dir.mktmpdir) + (tarball_name)
        @tarball_cache_root = Pathname.new(settings[:cache_root]) + (@forge_release.slug + "/tarball/")
        @tarball_cache_path = @tarball_cache_root + tarball_name

        md5_filename = @forge_release.slug + '.md5'
        @md5_file_path = @tarball_cache_root + md5_filename

        sha256_filename = @forge_release.slug + '.sha256'
        @sha256_file_path = @tarball_cache_root + sha256_filename

        @unpack_path   = Pathname.new(Dir.mktmpdir) + @forge_release.slug
      end

      # Download, unpack, and install this module release to the target directory.
      #
      # @example
      #   environment_path = Pathname.new('/etc/puppetlabs/puppet/environments/production')
      #   target_dir = environment_path + 'eight_hundred'
      #   mod = R10K::Forge::ModuleRelease.new('branan-eight_hundred', '8.0.0')
      #   mod.install(target_dir)
      #
      # @param target_dir [Pathname] The full path to where the module should be installed.
      # @return [void]
      def install(target_dir)
        download
        verify
        unpack(target_dir)
      ensure
        cleanup
      end

      # Download the module release to {#download_path} and cache to {#tarball_cache_path}
      #
      # @return [void]
      def download
        if @tarball_cache_path.exist?
          logger.debug1 "Using cached copy of #{@forge_release.slug} tarball"
        else
          logger.debug1 "Downloading #{@forge_release.slug} from #{PuppetForge::Release.conn.url_prefix} to #{@download_path}"
          @forge_release.download(download_path)
          FileUtils::mkdir_p(@tarball_cache_root)
          FileUtils::mv(@download_path, @tarball_cache_path)
        end
      end

      # Verify the module release cached in {#tarball_cache_path} against the
      # module release checksum given by the Puppet Forge. On mismatch, remove
      # the cached copy.
      #
      # @raise [R10K::Error] when no SHA256 is available and FIPS mode is on
      # @return [void]
      def verify
        logger.debug1 "Verifying that #{@tarball_cache_path} matches checksum"

        sha256_of_tarball = Digest(:SHA256).file(@tarball_cache_path).hexdigest

        if @sha256_file_path.exist?
          verify_from_file(sha256_of_tarball, @sha256_file_path)
        else
          if @forge_release.respond_to?(:file_sha256) && !@forge_release.file_sha256.nil? && !@forge_release.file_sha256.size.zero?
            forge_256_checksum = @forge_release.file_sha256
            verify_from_forge(sha256_of_tarball, forge_256_checksum, @sha256_file_path)
          else
            if R10K::Util::Platform.fips?
              raise R10K::Error, "Could not verify module, no SHA256 checksum available, and MD5 checksums not allowed in FIPS mode"
            end

            logger.debug1 "No SHA256 checksum available, falling back to MD5"
            md5_of_tarball = Digest(:MD5).file(@tarball_cache_path).hexdigest
            if @md5_file_path.exist?
              verify_from_file(md5_of_tarball, @md5_file_path)
            else
              verify_from_forge(md5_of_tarball, @forge_release.file_md5, @md5_file_path)
            end
          end
        end
      end

      # Verify the checksum of the cached tarball against the
      # module release checksum stored in the cache as well.
      # On mismatch, remove the cached copy of both files.
      # @param tarball_checksum [String] the checksum (either md5 or SHA256)
      #                         of the downloaded module tarball
      # @param file [Pathname] the file containing the checksum as downloaded
      #             previously from the forge
      # @param digest_class [Digest::SHA256, Digest::MD5] which checksum type
      #                     to verify with
      #
      # @raise [PuppetForge::V3::Release::ChecksumMismatch] The
      #   cached module release checksum doesn't match the cached checksum.
      #
      # @return [void]
      def verify_from_file(tarball_checksum, checksum_file_path)
        checksum_from_file = File.read(checksum_file_path).strip
        if tarball_checksum != checksum_from_file
          logger.error "Checksum of #{@tarball_cache_path} (#{tarball_checksum}) does not match checksum #{checksum_from_file} in #{checksum_file_path}. Removing both files."
          @tarball_cache_path.delete
          checksum_file_path.delete
          raise PuppetForge::V3::Release::ChecksumMismatch.new
        end
      end

      # Verify the checksum of the cached tarball against the
      # module release checksum from the forge.
      # On mismatch, remove the cached copy of the tarball.
      # @param tarball_checksum [String] the checksum (either md5 or SHA256)
      #                         of the downloaded module tarball
      # @param forge_checksum [String] the checksum downloaded from the Forge
      # @param checksum_file_path [Pathname] the path to write the verified
      #                            checksum to
      #
      # @raise [PuppetForge::V3::Release::ChecksumMismatch] The
      #   cached module release checksum doesn't match the forge checksum.
      #
      # @return [void]
      def verify_from_forge(tarball_checksum, forge_checksum, checksum_file_path)
        if tarball_checksum != forge_checksum
          logger.debug1 "Checksum of #{@tarball_cache_path} (#{tarball_checksum}) does not match checksum #{forge_checksum} found on the forge. Removing tarball."
          @tarball_cache_path.delete
          raise PuppetForge::V3::Release::ChecksumMismatch.new
        else
          File.write(checksum_file_path, forge_checksum)
        end
      end

      # Unpack the module release at {#tarball_cache_path}  into the given target_dir
      #
      # @param target_dir [Pathname] The final path where the module release
      #   should be unpacked/installed into.
      # @return [void]
      def unpack(target_dir)
        logger.debug1 _("Unpacking %{tarball_cache_path} to %{target_dir} (with tmpdir %{tmp_path})") % {tarball_cache_path: tarball_cache_path, target_dir: target_dir, tmp_path: unpack_path}
        file_lists = PuppetForge::Unpacker.unpack(tarball_cache_path.to_s, target_dir.to_s, unpack_path.to_s)
        logger.debug2 _("Valid files unpacked: %{valid_files}") % {valid_files: file_lists[:valid]}
        if !file_lists[:invalid].empty?
          logger.debug1 _("These files existed in the module's tar file, but are invalid filetypes and were not unpacked: %{invalid_files}") % {invalid_files: file_lists[:invalid]}
        end
        if !file_lists[:symlinks].empty?
          logger.warn _("Symlinks are unsupported and were not unpacked from the module tarball. %{release_slug} contained these ignored symlinks: %{symlinks}") % {release_slug: @forge_release.slug, symlinks: file_lists[:symlinks]}
        end
      end

      # Remove all files created while downloading and unpacking the module.
      def cleanup
        cleanup_unpack_path
        cleanup_download_path
      end

      # Remove the temporary directory used for unpacking the module.
      def cleanup_unpack_path
        if unpack_path.parent.exist?
          unpack_path.parent.rmtree
        end
      end

      # Remove the downloaded module release.
      def cleanup_download_path
        if download_path.parent.exist?
          download_path.parent.rmtree
        end
      end
    end
  end
end
