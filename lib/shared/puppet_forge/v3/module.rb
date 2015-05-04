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

      # Get a specific release of this module off of the forge.
      #
      # @return [ModuleRelease] a release object of the given version for this module.
      def release(version)
        PuppetForge::V3::ModuleRelease.new(@full_name, version).tap { |mr| mr.conn = conn }
      end
    end
  end
end
