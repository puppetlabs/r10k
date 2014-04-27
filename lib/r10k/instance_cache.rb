module R10K

  # This class implements a generic object memoization container. It caches
  # new objects and returns cached objects based on the instantiation arguments.
  class InstanceCache

    # Initialize a new registry with a given class
    #
    # @param klass [Class] The class to memoize
    # @param method [Symbol] The method name to use when creating objects.
    #                        Defaults to :new.
    def initialize(klass, method = :new)
      @klass  = klass
      @method = method
      @instances = {}
    end

    # Create a new object, or return a memoized object.
    #
    # @param args [*Object] The arguments to pass to the initialize method
    #
    # @return [Object] A memoized instance of the registered class
    def generate(*args)
      @instances[args] ||= @klass.send(@method, *args)
    end

    # Clear all memoized objects
    def clear!
      @instances = {}
    end
  end
end
