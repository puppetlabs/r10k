module R10K
  class ExecutionFailure < StandardError
    attr_accessor :exit_code, :stdout, :stderr
  end

  # An error class that accepts an optional hash.
  #
  # @overload initialize(message)
  #   @param message [String] The exception message
  #
  # @overload initialize(message, options)
  #   @param message [String] The exception message
  #   @param options [Hash] A set of options to store on the exception
  #
  # @overload initialize(options)
  #   @param options [Hash] A set of options to store on the exception
  #
  class R10KError < StandardError
    def initialize(message = nil, options = {})
      if message.is_a? String
        super(message)
        @options = options
      elsif message.is_a? Hash
        @options = message
        message = nil
      end
    end
  end
end
