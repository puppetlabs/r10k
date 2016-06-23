require 'r10k/logging'

module R10K
  # Detect whether a given feature is present or absent
  class Feature

    include R10K::Logging

    # @attribute [r] name
    #   @return [Symbol] The name of this feature
    attr_reader :name

    # @param name [Symbol] The name of this feature
    # @param opts [Hash]
    # @param block [Proc] An optional block to detect if this feature is available
    #
    # @option opts [String, Array<String>] :libraries One or more libraries to
    #   require to make sure this feature is present.
    def initialize(name, opts = {}, &block)
      @name      = name
      @libraries = Array(opts.delete(:libraries))
      @block     = block
    end

    # @return [true, false] Is this feature available?
    def available?
      logger.debug1 { _("Testing to see if feature %{name} is available.") % {name: @name} }
      rv = @libraries.all? { |lib| library_available?(lib) } && proc_available?
      msg = rv ? "is" : "is not"
      logger.debug1 { _("Feature %{name} %{message} available.") % {name: @name, message: msg} }
      rv
    end

    private

    def library_available?(lib)
      logger.debug2 { _("Attempting to load library '%{lib}' for feature %{name}") % {lib: lib, name: @name} }
      require lib
      true
    rescue ScriptError => e
      logger.debug2 { _("Error while loading library %{lib} for feature %{name}: %{error_msg}") % {lib: lib, name: @name, error_msg: e.message} }
      false
    end

    def proc_available?
      if @block
        logger.debug2 { _("Evaluating proc %{block} to test for feature %{name}") % {block: @block.inspect, name: @name} }
        output = @block.call
        logger.debug2 { _("Proc %{block} for feature %{name} returned %{output}") % {block: @block.inspect, name: @name, output: output.inspect } }
        !!output
      else
        true
      end
    end
  end
end
