module R10K
  # Detect whether a given feature is present or absent
  class Feature

    # @attribute [r] name
    #   @return [Symbol] The name of this feature
    attr_reader :name

    # @param name [Symbol] The name of this feature
    # @param opts [Hash]
    #
    # @option opts [String, Array<String>] :libraries One or more libraries to
    #   require to make sure this feature is present.
    def initialize(name, opts = {})
      @name      = name
      @libraries = Array(opts.delete(:libraries))
    end

    # @return [true, false] Is this feature available?
    def available?
      @libraries.all? { |lib| library_available?(lib) }
    end

    private

    def library_available?(lib)
      require lib
      true
    rescue ScriptError
      false
    end
  end
end
