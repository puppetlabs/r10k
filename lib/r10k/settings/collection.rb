require 'r10k/settings/definition'
require 'r10k/util/setopts'
require 'r10k/util/symbolize_keys'

module R10K
  module Settings

    # Define a group of settings, which can be single definitions or nested
    # collections.
    class Collection

      # @!attribute [r] name
      #   @return [String] The name of this collection
      attr_reader :name

      # @param name [Symbol] The name of the collection
      # @param settings [Array] All settings in this collection
      def initialize(name, settings)
        @name = name
        @settings = Hash[settings.map { |s| [s.name, s] }]
      end

      # Assign a hash of values to the settings in this collection.
      #
      # If the passed hash contains any invalid settings values, the names
      # of those settings are stored for use in the {#validate} method.
      #
      # @param newvalues [Hash]
      # @return [void]
      def assign(newvalues)
        R10K::Util::SymbolizeKeys.symbolize_keys!(newvalues)
        @settings.each_pair do |name, setting|
          if newvalues.key?(name)
            setting.assign(newvalues[name])
          end
        end

        invalid = newvalues.keys - @settings.keys
        if !invalid.empty?
          @invalid_settings = invalid
        end
      end

      # Evaluate all settings and return a frozen hash of the final values.
      # @return [Hash]
      def resolve
        rv = {}
        @settings.each_pair do |name, setting|
          rv[name] = setting.resolve
        end
        rv.freeze
      end
    end
  end
end
