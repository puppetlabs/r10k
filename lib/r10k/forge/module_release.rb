require 'shared/puppet_forge/v3/module_release'
require 'fileutils'

module R10K
  module Forge
    # Download, unpack, and install modules from the Puppet Forge
    class ModuleRelease

      # @!attribute [r] forge_release
      #   @api private
      #   @return [PuppetForge::V3::ModuleRelease] The Forge V3 API module
      #     release object used for downloading and verifying the module
      #     release.
      attr_reader :forge_release

      # @!attribute [rw] download_path
      #   @return [Pathname] Where the module tarball will be downloaded to.
      attr_accessor :download_path

      # @!attribute [rw] unpack_path
      #   @return [Pathname] Where the module will be unpacked to.
      attr_accessor :unpack_path

      # @param full_name [String] The hyphen separated name of the module
      # @param version [String] The version of the module
      def initialize(full_name, version)
        @full_name = PuppetForge::V3.normalize_name(full_name)
        @version   = version

        @forge_release = PuppetForge::V3::ModuleRelease.new(@full_name, @version)

        #@download_path = Pathname.new(R10K::Settings[:forge][:module_cache]) + "#{@forge_release.slug}.tgz"
        #@unpack_path   = Pathname.new(R10K::Settings[:forge][:unpack_tmpdir]) + @forge_release.slug
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
        unpack
        move(target_dir)
      ensure
        cleanup
      end

      # Download the module release to {#download_path}
      #
      # @return [void]
      def download
        @forge_release.download(download_path)
      end

      # Verify the module release downloaded to {#download_path} against the
      # module release checksum given by the Puppet Forge
      #
      # @raise [PuppetForge::V3::ModuleRelease::ChecksumMismatch] The
      #   downloaded module release checksum doesn't match the expected Forge
      #   module release checksum.
      # @return [void]
      def verify
        @forge_release.verify(download_path)
      end

      # Unpack the module release at {#download_path} to {#unpack_path}
      def unpack
        PuppetForge::Unpacker.unpack(download_path, unpack_path)
      end

      # Move the unpacked module release at {#module_path} to the target directory.
      #
      # @param target_dir [Pathname] The path to where the module release should be created.
      # @return [void]
      def move(target_dir)
        PuppetForge::Unpacker.harmonize_ownership(unpack_path, target_dir)
        FileUtils.mv(tmpdir, target_dir)
      end

      # Remove all files created while downloading and unpacking the module.
      def cleanup
        cleanup_unpack_path
        cleanup_download_path
      end

      # Remove the temporary directory used for unpacking the module.
      def cleanup_unpack_path
        if unpack_path.exist?
          unpack_path.rmtree
        end
      end

      # Remove the downloaded module release.
      def cleanup_download_path
        if download_path.exist?
          download_path.delete
        end
      end
    end
  end
end
