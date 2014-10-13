module R10K
  module Action
    class Runner
      def initialize(argv, opts, klass)
        @argv = argv
        @opts = opts
        @klass = klass
      end

      def call
        setup_logging
        setup_settings
        # check arguments
        @klass.new(@argv, @opts).call
      end

      def setup_logging
        if @opts[:loglevel]
          R10K::Logging.level = @opts.delete(:loglevel)
        end
      end

      def setup_settings
      end
    end
  end
end
