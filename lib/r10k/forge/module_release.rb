require 'r10k/logging'
require 'r10k/settings/mixin'
require 'fileutils'
require 'forwardable'
require 'tmpdir'
require 'puppet_forge'

module R10K
  module Forge
    # Download, unpack, and install modules from the Puppet Forge
    class ModuleRelease

      include R10K::Settings::Mixin

      def_setting_attr :proxy
      def_setting_attr :baseurl

      include R10K::Logging

      # @!attribute [r] forge_release
      #   @api private
      #   @return [PuppetForge::V3::ModuleRelease] The Forge V3 API module
      #     release object used for downloading and verifying the module
      #     release.
      attr_reader :forge_release

      extend Forwardable

      def_delegators :@forge_release, :slug, :data

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

        PuppetForge::V3::Release.conn = conn
        @forge_release = PuppetForge::V3::Release.new({ :name => @full_name, :version => @version, :slug => "#{@full_name}-#{@version}" })

        @download_path = Pathname.new(Dir.mktmpdir) + (slug + '.tar.gz')
        @unpack_path   = Pathname.new(Dir.mktmpdir) + slug
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

      # Download the module release to {#download_path}
      #
      # @return [void]
      def download
        logger.debug1 "Downloading #{@forge_release.slug} from #{PuppetForge::Release.conn.url_prefix} to #{@download_path}"
        @forge_release.download(download_path)
      end

      # Verify the module release downloaded to {#download_path} against the
      # module release checksum given by the Puppet Forge
      #
      # @raise [PuppetForge::V3::Release::ChecksumMismatch] The
      #   downloaded module release checksum doesn't match the expected Forge
      #   module release checksum.
      # @return [void]
      def verify
        logger.debug1 "Verifying that #{download_path} matches checksum #{data['file_md5']}"
        @forge_release.verify(download_path)
      end

      # Unpack the module release at {#download_path} into the given target_dir
      #
      # @param target_dir [Pathname] The final path where the module release
      #   should be unpacked/installed into.
      # @return [void]
      def unpack(target_dir)
        logger.debug1 "Unpacking #{download_path} to #{target_dir} (with tmpdir #{unpack_path})"
        file_lists = PuppetForge::Unpacker.unpack(download_path.to_s, target_dir.to_s, unpack_path.to_s)
        logger.debug2 "Valid files unpacked: #{file_lists[:valid]}"
        if !file_lists[:invalid].empty?
          logger.warn "These files existed in the module's tar file, but are invalid filetypes and were not " +
                      "unpacked: #{file_lists[:invalid]}"
        end
        if !file_lists[:symlinks].empty?
          raise R10K::Error, "Symlinks are unsupported and were not unpacked from the module tarball. " + 
                             "#{@forge_release.slug} contained these ignored symlinks: #{file_lists[:symlinks]}"
        end
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

      private

      def conn
        if settings[:baseurl]
          PuppetForge.host = settings[:baseurl]
          conn = PuppetForge::Connection.make_connection(settings[:baseurl])
        else
          PuppetForge.host = "https://forgeapi.puppetlabs.com"
          conn = PuppetForge::Connection.default_connection
        end
        conn.proxy(proxy)
        conn
      end

      def proxy
        [
          settings[:proxy],
          ENV['HTTPS_PROXY'],
          ENV['https_proxy'],
          ENV['HTTP_PROXY'],
          ENV['http_proxy']
        ].find { |value| value }
      end
    end
  end
end
