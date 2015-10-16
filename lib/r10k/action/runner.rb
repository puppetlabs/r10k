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

        @settings = {}
      end

      def instance
        if @_instance.nil?
          iopts = @opts.dup
          iopts.delete(:loglevel)
          @_instance = @klass.new(iopts, @argv, @settings)
        end
        @_instance
      end

      def call
        setup_logging
        setup_settings
        # @todo check arguments
        setup_authorization
        instance.call
      end

      def setup_logging
        if @opts.key?(:loglevel)
          R10K::Logging.level = @opts[:loglevel]
        end
      end

      def setup_settings
        config_settings = settings_from_config(@opts[:config])

        overrides = {:cachedir => @opts[:cachedir]}
        overrides.delete_if { |_, val| val.nil? }

        with_overrides = config_settings.merge(overrides) do |key, oldval, newval|
          logger.debug2 "Overriding config file setting '#{key}': '#{oldval}' -> '#{newval}'"
          newval
        end

        @settings = R10K::Settings.global_settings.evaluate(with_overrides)

        R10K::Initializers::GlobalInitializer.new(@settings).call
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

      private

      def settings_from_config(override_path, requires_config = false)
        loader = R10K::Settings::Loader.new
        path = loader.search(override_path)
        results = {}

        if path
          logger.debug2 "Reading configuration from #{path.inspect}"
          results = loader.read(path)
        else
          logger.debug2 "No config file explicitly given and no default config file could be found, default settings will be used."
        end

        results
      end
    end
  end
end
