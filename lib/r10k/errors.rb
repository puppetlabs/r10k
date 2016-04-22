require 'r10k'

module R10K

  # An error class that accepts an optional hash and wrapped error message
  #
  class Error < StandardError
    attr_accessor :original

    # Generate a wrapped exception
    #
    # @param original [Exception] The exception to wrap
    # @param mesg [String]
    # @param options [Hash]
    #
    # @return [R10K::Error]
    def self.wrap(original, mesg, options = {})
      new(mesg, options).tap do |e|
        e.set_backtrace(caller(4))
        e.original = original
      end
    end

    # @overload initialize(mesg)
    #   @param mesg [String] The exception mesg
    #
    # @overload initialize(mesg, options)
    #   @param mesg [String] The exception mesg
    #   @param options [Hash] A set of options to store on the exception
    #
    # @options options [Array<String>] :backtrace
    def initialize(mesg, options = {})
      super(mesg)

      bt = options.delete(:backtrace)
      if bt
        set_backtrace(bt)
      end

      @options = options
    end

    protected

    def structure_exception(name, exc)
      struct = []
      struct << "#{name}:"
      if exc.respond_to?(:format)
        struct << indent(exc.format)
      else
        struct << indent(exc.message)
      end
      struct.join("\n")
    end

    def indent(str, level = 4)
      prefix = ' ' * level
      str.gsub(/^/, prefix)
    end
  end
end
