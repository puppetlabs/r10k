require 'shared/puppet_forge/v3'
require 'shared/puppet_forge/v3/module_release'
require 'shared/puppet_forge/connection'

module PuppetForge
  module V3
    # Represents metadata for a single Forge module and provides access to
    # the releases of a module.
    class Module

      include PuppetForge::Connection

      # @!attribute [r] full_name
      #   @return [String] The hyphen separated full name of this module
      attr_reader :full_name

      # @param full_name [String] The name of this module, will be normalized to
      #   a hyphen separated name.
      def initialize(full_name)
        @full_name = PuppetForge::V3.normalize_name(full_name)
      end

      # Get all released versions of this module
      #
      # @example
      #   mod = PuppetForge::V3::Module.new('timmy-boolean')
      #   mod.versions
      #   #=> ["0.9.0-rc1", "0.9.0", "1.0.0", "1.0.1"]
      #
      # @return [Array<String>] All published versions of the given module
      def versions
        path = "/v3/modules/#{@full_name}"
        response = conn.get(path)

        releases = []

        response.body['releases'].each do |release|
          if !release['deleted_at']
            releases << release['version']
          end
        end

        releases.reverse
      end

      # Get all released versions of this module
      #
      # @example
      #   mod = PuppetForge::V3::Module.new('timmy-boolean')
      #   mod.latest_version
      #   #=> "1.0.1"
      #
      # @return [String] The latest published version of the given module
      def latest_version
        versions.last
      end

      # Get a specific release of this module off of the forge.
      #
      # @return [ModuleRelease] a release object of the given version for this module.
      def release(version)
        PuppetForge::V3::ModuleRelease.new(@full_name, version).tap { |mr| mr.conn = conn }
      end
    end
  end
end
