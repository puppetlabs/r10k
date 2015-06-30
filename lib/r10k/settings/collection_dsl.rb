require 'r10k/settings/collection'
require 'r10k/settings/collection_maker'

module R10K
  module Settings
    # Define a simple DSL for creating settings collections.
    #
    # This adds a R10K::Settings::CollectionMaker instance to inheriting classes,
    # delegates the necessary methods to the maker instance, and automatically
    # populates new instances with the appropriate definitions.
    #
    # Inheriting classes should define #initialize with an arity of zero and
    # call the superclass with the name of the collection.
    #
    # @example
    #   class SomeCollection < R10K::Settings::CollectionDSL
    #     def initialize
    #       super(:collection_name)
    #     end
    #
    #     add_setting(
    #       :my_setting,
    #       {
    #         :desc => "The description for my setting",
    #         :default => "some default",
    #       }
    #     )
    #
    #     add_collection(R10K::Settings:AnotherCollection)
    #   end
    #
    #   collection = R10K::Settings::SomeCollection.new
    #   collection.get(:my_setting) #=> "some default"
    #
    # @abstract
    class CollectionDSL < R10K::Settings::Collection
      class << self

        # @!attribute [r] maker
        #   @api private
        #   @return [R10K::Settings::CollectionMaker]
        attr_accessor :maker

        # Add a new maker instance to each subclass.
        def inherited(klass)
          klass.maker = R10K::Settings::CollectionMaker.new
        end

        extend Forwardable

        def_delegators :@maker, :add_setting, :add_collection, :definitions, :collections
        private :add_setting, :add_collection
      end

      def initialize(name)
        super(name, self.class.definitions, self.class.collections)
      end
    end
  end
end
