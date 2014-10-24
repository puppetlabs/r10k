require 'r10k'

module R10K

  # @deprecated
  class ExecutionFailure < StandardError
    attr_accessor :exit_code, :stdout, :stderr
  end

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
    def initialize(mesg, options = {})
      super(mesg)
      @options = options
    end
  end

  # @deprecated
  R10KError = Error
end
