module R10K
  module Settings
    # Define a group of settings definitions and optional nested collections and
    # handle fetching and assigning values for definitions and nested collections.
    #
    # @example A flat collection
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
    # @example A collection with a nested collection
    #   definitions = [
    #     R10K::Settings::Definition.new(:topval),
    #   ]
    #   collections = [
    #     R10K::Settings::Collection.new(:nested, [...])
    #   ]
    #   collection = R10K::Settings::Collection.new(:coll, definitions, collections)
    #
    #   collection.get(:nested) #=> #<R10K::Settings::Collection name=:nested>
    #   collection.get(:nested).set(:nestedval) #=> nil
    #
    #   collection.set(:nested) #=> ArgumentError, "Cannot set value of nested collection nested; set individual values on the nested collection instead."
    #
    class Collection

      # @!attribute [r] name
      #   @return [Symbol] The name of this settings collection
      attr_reader :name

      # @!attribute [r] definitions
      #   @return [Array<R10K::Settings::Definition>]
      attr_reader :definitions

      # @!attribute [r] collections
      #   @return [Array<R10K::Settings::Collection>] A list of nested collections
      attr_reader :collections

      # @!attribute [rw] parent
      #   @return [R10K::Settings::Collection] An optional collection that contains
      #     this collection.
      attr_accessor :parent

      # @param name [Symbol] The name of this collection
      # @param definition_list [Array<R10K::Settings::Definition>] A list of
      #   definitions to include in this collection.
      # @param collection_list [Array<R10K::Settings::Collection>] An optional
      #   list of collections to use as nested collections.
      def initialize(name, definition_list, collection_list = [])
        @name = name
        @definitions = {}
        @collections = {}

        definition_list.each do |defn|
          defn.collection = self
          @definitions[defn.name] = defn
        end

        collection_list.each do |coll|
          coll.parent = self
          @collections[coll.name] = coll
        end
      end

      # Get the value of the given setting.
      #
      # @param name [Symbol] The name of the setting to look up
      # @raise [ArgumentError] If the requested setting isn't defined
      # @return [R10K::Settings::Collection, Object] The settings collection if
      #   the setting references a collection, otherwise the looked up value of
      #   the setting.
      def get(name)
        if @definitions[name]
          @definitions[name].get
        elsif @collections[name]
          @collections[name]
        else
          raise ArgumentError, "Cannot get value of nonexistent setting #{name}"
        end
      end

      alias [] get

      # Set the value of the given setting.
      #
      # @param name [Symbol] The name of the setting to look up
      # @param value [Object] The value to set the setting to
      # @raise [ArgumentError] If the requested setting isn't defined or the
      #   setting points to a nested collection.
      # @return [void]
      def set(name, value)
        if @definitions[name]
          @definitions[name].set(value)
        elsif @collections[name]
          raise ArgumentError, "Cannot set value of nested collection #{name}; set individual values on the nested collection instead."
        else
          raise ArgumentError, "Cannot set value of nonexistent setting #{name}"
        end
      end

      alias []= set
    end
  end
end
