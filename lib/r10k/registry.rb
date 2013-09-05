module R10K
  class Registry
    def initialize(klass, method = :new)
      @klass  = klass
      @method = method
      @instances = {}
    end

    def generate(*args)
      @instances[args] ||= @klass.send(@method, *args)
    end

    def clear!
      @instances = {}
    end
  end
end
