module R10K
  module Settings
    # Define a group of settings definitions and handle fetching and assigning
    # values for those definitions.
    #
    # @example
    #   definitions = [
    #     R10K::Settings::Definition.new(:someval),
    #     R10K::Settings::Definition.new(:somedefaultvalue, :default => "stuff")
    #   ]
    #   collection = R10K::Settings::Collection.new(:coll, definitions)
    #
    #   collection.get(:someval) #=> nil
    #   collection.get(:somedefaultvalue) #=> "stuff"
    #
    #   collection.set(:someval, "newvalue")
    #   collection.get(:someval) #=> "newvalue"
    #
    #   collection.get(:novalue) #=> ArgumentError, "Cannot get value of nonexistent setting novalue"
    #
    class Collection

      # @!attribute [r] name
      #   @return [Symbol] The name of this settings collection
      attr_reader :name

      # @!attribute [r] definitions
      #   @return [Array<R10K::Settings::Definition>]
      attr_reader :definitions

      # @param name [Symbol]
      # @param definition_list [Array<R10K::Settings::Definition>]
      def initialize(name, definition_list)
        @name = name
        @definitions = {}

        definition_list.each do |defn|
          defn.collection = self
          @definitions[defn.name] = defn
        end
      end

      # Get the value of the given setting.
      #
      # @param name [Symbol] The name of the setting to look up
      # @raise [ArgumentError] If the requested setting isn't defined
      # @return [Object] The setting value
      def get(name)
        defn = @definitions[name]
        if defn
          defn.get
        else
          raise ArgumentError, "Cannot get value of nonexistent setting #{name}"
        end
      end

      alias [] get

      # Set the value of the given setting.
      #
      # @param name [Symbol] The name of the setting to look up
      # @param value [Object] The value to set the setting to
      # @raise [ArgumentError] If the requested setting isn't defined
      # @return [void]
      def set(name, value)
        defn = @definitions[name]
        if defn
          defn.set(value)
        else
          raise ArgumentError, "Cannot set value of nonexistent setting #{name}"
        end
      end

      alias []= set
    end
  end
end
