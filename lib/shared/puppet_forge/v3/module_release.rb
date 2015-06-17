require 'shared/puppet_forge/v3'
require 'shared/puppet_forge/connection'
require 'shared/puppet_forge/error'

module PuppetForge
  module V3
    # Access metadata and downloads for a specific module release.
    class ModuleRelease

      include PuppetForge::Connection

      # @!attribute [r] full_name
      #   @return [String] The hyphen delimited name of this module
      attr_reader :full_name

      # @!attribute [r] version
      #   @return [String] The version of this module
      attr_reader :version

      # @param full_name [String] The name of the module, will be normalized
      #   to a hyphen delimited name.
      # @param version [String]
      def initialize(full_name, version)
        @full_name = PuppetForge::V3.normalize_name(full_name)
        @version   = version
      end

      # @return [Hash] The complete Forge response for this release.
      def data
        @data ||= conn.get(resource_url).body
      rescue Faraday::ResourceNotFound => e
        raise PuppetForge::ModuleReleaseNotFound, "The module release #{slug} does not exist on #{conn.url_prefix}.", e.backtrace
      end

      # @return [String] The unique identifier for this module release.
      def slug
        "#{full_name}-#{version}"
      end

      # Download this module release to the specified path.
      #
      # @param path [Pathname]
      # @return [void]
      def download(path)
        resp = conn.get(file_url)
        path.open('wb') { |fh| fh.write(resp.body) }
      rescue Faraday::ResourceNotFound => e
        raise PuppetForge::ModuleReleaseNotFound, "The module release #{slug} does not exist on #{conn.url_prefix}.", e.backtrace
      end

      # Verify that a downloaded module matches the checksum in the metadata for this release.
      #
      # @param path [Pathname]
      # @return [void]
      def verify(path)
        expected_md5 = data['file_md5']
        file_md5     = Digest::MD5.file(path).hexdigest
        if expected_md5 != file_md5
          raise ChecksumMismatch.new("Expected #{path} checksum to be #{expected_md5}, got #{file_md5}")
        end
      end

      private

      def file_url
        "/v3/files/#{slug}.tar.gz"
      end

      def resource_url
        "/v3/releases/#{slug}"
      end

      class ChecksumMismatch < StandardError

      end
    end
  end
end
