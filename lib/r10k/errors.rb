module R10K
  class ExecutionFailure < StandardError
    attr_accessor :exit_code, :stdout, :stderr
  end

  # An error class that accepts an optional hash.
  #
  # @overload initialize(mesg)
  #   @param mesg [String] The exception mesg
  #
  # @overload initialize(mesg, options)
  #   @param mesg [String] The exception mesg
  #   @param options [Hash] A set of options to store on the exception
  #
  # @overload initialize(options)
  #   @param options [Hash] A set of options to store on the exception
  #
  class R10KError < StandardError
    def initialize(mesg = nil, options = {})
      if mesg.is_a? String
        super(mesg)
        @mesg    = mesg
        @options = options
      elsif mesg.is_a? Hash
        @mesg    = nil
        @options = mesg
      elsif mesg.nil? and options
        @options = options
      end
    end
  end
end
