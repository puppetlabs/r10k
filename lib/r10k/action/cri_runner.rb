require 'r10k/action/runner'

module R10K
  module Action

    # Adapt the Cri runner interface to the R10K::Action::Runner interface
    #
    # This class provides the necessary glue to translate behavior specific
    # to Cri and the CLI component in general to the interface agnostic runner
    # class.
    class CriRunner

      def self.wrap(klass)
        new(klass)
      end

      def initialize(klass)
        @klass = klass
      end

      # @todo swap args order for consistency
      def new(opts, args, _cmd)

        # Translate from the Cri verbose logging option to the internal logging setting.
        loglevel = opts.delete(:verbose)
        case loglevel
        when String, Numeric
          opts[:loglevel] = loglevel
        when TrueClass
          opts[:loglevel] = 'INFO'
        else
          # When the type is unsure just pass it in as-is and let the internals
          # raise the appropriate errors.
          opts[:loglevel] = loglevel
        end

        R10K::Action::Runner.new(args, opts, @klass)
      end
    end
  end
end
