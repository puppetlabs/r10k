module R10K
  module Action
    class Runner
      def initialize(opts, argv, klass)
        @opts = opts
        @argv = argv
        @klass = klass
      end

      def instance
        if @_instance.nil?
          iopts = @opts.dup
          iopts.delete(:loglevel)
          @_instance = @klass.new(iopts, @argv)
        end
        @_instance
      end

      def call
        setup_logging
        setup_settings
        # @todo check arguments
        instance.call
      end

      def setup_logging
        if @opts.key?(:loglevel)
          R10K::Logging.level = @opts[:loglevel]
        end
      end

      def setup_settings
      end
    end
  end
end
