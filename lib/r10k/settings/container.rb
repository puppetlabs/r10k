# Defines a collection for application settings
#
# This implements a hierarchical interface to application settings. Containers
# can define an optional parent container that will be used for default options
# if those options aren't set on the given container.
module R10K
  module Settings
    class Container

      # @!attribute [r] valid_keys
      #   @return [Set<Symbol>] All valid keys defined on the container or parent container.
      attr_accessor :valid_keys

      # @param parent [R10K::Settings::Container] An optional parent container
      def initialize(parent = nil)
        @parent = parent

        @valid_keys = Set.new
        @settings = {}
      end

      # Look up a value in the container. The lookup checks the current container,
      # and then falls back to the parent container if it's given.
      #
      # @param key [Symbol] The lookup key
      #
      # @return [Object, nil] The retrieved value if present.
      #
      # @raise [R10K::Settings::Container::InvalidKey] If the looked up key isn't
      #   a valid key.
      def [](key)
        validate_key! key

        if @settings[key]
          @settings[key]
        elsif @parent && (pkey = @parent[key])
          @settings[key] = pkey.dup
          @settings[key]
        end
      end

      # Set a value on the container
      #
      # @param key [Symbol] The lookup key
      # @param value [Object] The value to store in the container
      #
      # @raise [R10K::Settings::Container::InvalidKey] If the looked up key isn't
      #   a valid key.
      def []=(key, value)
        validate_key! key

        @settings[key] = value
      end

      # Define a valid container key
      #
      # @note This should only be used by {#R10K::Settings::ClassSettings}
      #
      # @param key [Symbol]
      # @return [void]
      def add_valid_key(key)
        @valid_keys.add(key)
      end

      # Determine if a key is a valid setting.
      #
      # @param key [Symbol]
      #
      # @return [true, false]
      def valid_key?(key)
        if @valid_keys.include?(key)
          true
        elsif @parent and @parent.valid_key?(key)
          @valid_keys.add(key)
          true
        end
      end

      # Clear all existing settings in this container. Valid settings are left alone.
      # @return [void]
      def reset!
        @settings = {}
      end

      private

      def validate_key!(key)
        unless valid_key?(key)
          raise InvalidKey, "Key #{key} is not a valid key"
        end
      end

      # @api private
      class InvalidKey < StandardError; end
    end
  end
end
