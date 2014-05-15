module R10K

  # This implements a factory by storing classes indexed with a given key and
  # creates objects based on that key.
  class KeyedFactory

    # @!attribute [r] implementations
    #   @return [Hash<Object, Class>] A hash of keys and the associated
    #     implementations that this factory can generate.
    attr_reader :implementations

    def initialize
      @implementations = {}
    end

    def register(key, klass)
      if @implementations.has_key?(key)
        raise DuplicateImplementationError, "Class already registered for #{key}"
      else
        @implementations[key] = klass
      end
    end

    def retrieve(key)
      @implementations[key]
    end

    def generate(key, *args)
      if (impl = @implementations[key])
        impl.new(*args)
      else
        raise UnknownImplementationError, "No class registered for #{key}"
      end
    end

    class DuplicateImplementationError < StandardError; end
    class UnknownImplementationError < StandardError; end
  end
end
