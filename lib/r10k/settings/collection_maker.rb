require 'r10k/settings/collection'
require 'r10k/settings/definition'

module R10K
  module Settings
    # Defines an API for gathering information to make a new Collection
    #
    # This class defines an interface for creating definition information which
    # allows this class to define a "template" for Collection instances. It
    # generates definition instances instead of having instances being handed
    # to them to make sure that collections created from this don't accidentally
    # reuse the same definition instances.
    class CollectionMaker

      # @!attribute [r] stored_definitions
      #   @return [Array<Array<Symbol, Hash>>] A list of stored settings definitions
      attr_reader :stored_definitions

      def initialize
        @stored_definitions = []
      end

      # Add a new setting definition
      #
      # @param name [Symbol] The name of the new definition
      # @param opts [Hash] Information for this new setting. The exact set of
      #   valid keys depends on the class set by the :type key.
      #
      # @options opts [Class] :type The class for this Definition; defaults
      #   to {R10K::Settings::Definition}.
      # @return [void]
      def add_setting(name, opts)
        @stored_definitions << [name, opts]
      end

      # @return [Array<R10K::Settings::Definition>] A unique list of definition instances
      #   that can be passed to {R10K::Settings::Collection#initialize}
      def definitions
        @stored_definitions.map do |(name, opts)|
          defn_type = opts.delete(:type) || R10K::Settings::Definition
          defn_type.new(name, opts)
        end
      end
    end
  end
end
