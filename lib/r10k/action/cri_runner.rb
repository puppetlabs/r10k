require 'r10k/action/runner'

module R10K
  module Action

    # Adapt the Cri runner interface to the R10K::Action::Runner interface
    #
    # This class provides the necessary glue to translate behavior specific
    # to Cri and the CLI component in general to the interface agnostic runner
    # class.
    #
    # @api private
    class CriRunner

      def self.wrap(klass)
        new(klass)
      end

      def initialize(klass)
        @klass = klass
      end

      # Intercept any instatiations of klass
      #
      # Defining #new allows this object to proxy method calls on the wrapped
      # runner and decorate various methods. Doing so allows this class to
      # manage CLI specific behaviors and isolate the underlying code from
      # having to deal with those particularities
      #
      # @param opts [Hash]
      # @param argv [Array<String>]
      # @param _cmd [Cri::Command] The command that was invoked. This value
      #   is not used and is only present to adapt the Cri interface to r10k.
      # @return [self]
      def new(opts, args, _cmd = nil)
        # Translate from the Cri verbose logging option to the internal logging setting.
        loglevel = opts.delete(:verbose)
        case loglevel
        when String, Numeric
          opts[:loglevel] = loglevel
        when TrueClass
          opts[:loglevel] = 'INFO'
        when NilClass
          # pass
        else
          # When the type is unsure just pass it in as-is and let the internals
          # raise the appropriate errors.
          opts[:loglevel] = loglevel
        end

        @runner = R10K::Action::Runner.new(opts, args, @klass)

        self
      end

      # Invoke the wrapped behavior, determine if it succeeded, and exit with
      # the resulting exit code.
      def call
        rv = @runner.call
        exit(rv ? 0 : 1)
      end
    end
  end
end
