module R10K
  module Action
    class Runner
      def initialize(opts, argv, klass)
        @opts = opts
        @argv = argv
        @klass = klass
      end

      def call
        setup_logging
        setup_settings
        # check arguments
        @klass.new(@opts, @argv).call
      end

      def setup_logging
        if @opts.key?(:loglevel)
          R10K::Logging.level = @opts.delete(:loglevel)
        end
      end

      def setup_settings
      end
    end
  end
end
