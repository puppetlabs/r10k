require 'r10k/logging'
require 'r10k/errors'
require 'r10k/util/license'
require 'puppet_forge/connection'

module R10K
  module Action
    class Runner
      include R10K::Logging

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
        setup_authorization
      end

      def setup_authorization
        begin
          license = R10K::Util::License.load

          if license.respond_to?(:authorization_token)
            PuppetForge::Connection.authorization = license.authorization_token
          end
        rescue R10K::Error => e
          logger.warn e.message
        end
      end
    end
  end
end
