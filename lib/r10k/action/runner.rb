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

        overrides = {}
        overrides[:cachedir] = @opts[:cachedir] if @opts.key?(:cachedir)
        if @opts.key?(:'puppet-path') || @opts.key?(:'generate-types') || @opts.key?(:'deploy-spec') || @opts.key?(:'puppet-conf')
          overrides[:deploy] = {}
          overrides[:deploy][:puppet_path] = @opts[:'puppet-path'] if @opts.key?(:'puppet-path')
          overrides[:deploy][:puppet_conf] = @opts[:'puppet-conf'] if @opts.key?(:'puppet-conf')
          overrides[:deploy][:generate_types] = @opts[:'generate-types'] if @opts.key?(:'generate-types')
          overrides[:deploy][:deploy_spec] = @opts[:'deploy-spec'] if @opts.key?(:'deploy-spec')
        end

        with_overrides = config_settings.merge(overrides) do |key, oldval, newval|
          newval = oldval.merge(newval) if oldval.is_a? Hash
          logger.debug2 _("Overriding config file setting '%{key}': '%{old_val}' -> '%{new_val}'") % {key: key, old_val: oldval, new_val: newval}
          newval
        end

        # Credentials from the CLI override both the global and per-repo
        # credentials from the config, and so need to be handled specially
        with_overrides = add_credential_overrides(with_overrides)

        @settings = R10K::Settings.global_settings.evaluate(with_overrides)

        R10K::Initializers::GlobalInitializer.new(@settings).call
      rescue R10K::Settings::Collection::ValidationError => e
        logger.error e.format
        exit(8)
      end

      # Set up authorization from license file if it wasn't
      # already set via the config
      def setup_authorization
        if PuppetForge::Connection.authorization.nil?
          begin
            license = R10K::Util::License.load

            if license.respond_to?(:authorization_token)
              logger.debug "Using token from license to connect to the Forge."
              PuppetForge::Connection.authorization = license.authorization_token
            end
          rescue R10K::Error => e
            logger.warn e.message
          end
        end
      end

      private

      def settings_from_config(override_path)
        loader = R10K::Settings::Loader.new
        path = loader.search(override_path)
        results = {}

        if path
          @opts[:config] = path
          logger.debug2 _("Reading configuration from %{config_path}") % {config_path: path.inspect}
          results = loader.read(path)
        else
          logger.debug2 _("No config file explicitly given and no default config file could be found, default settings will be used.")
        end

        results
      end

      def add_credential_overrides(overrides)
        sshkey_path = @opts[:'private-key']
        token_path = @opts[:'oauth-token']
        app_id = @opts[:'github-app-id']
        app_private_key_path = @opts[:'github-app-key']
        app_ttl = @opts[:'github-app-ttl']

        if sshkey_path && token_path
          raise R10K::Error, "Cannot specify both an SSH key and a token to use with this deploy."
        end

        if sshkey_path && app_private_key_path
          raise R10K::Error, "Cannot specify both a SSH key and a SSL key to use with this deploy."
        end

        if app_id && token_path
          raise R10K::Error, "Cannot specify both a Github App and a token to use with this deploy."
        end

        if app_id && ! app_private_key_path or app_private_key_path && ! app_id
          raise R10K::Error, "Both id and private key are required with Github App to use with this deploy."
        end

        if sshkey_path
          overrides[:git] ||= {}
          overrides[:git][:private_key] = sshkey_path
          if repo_settings = overrides[:git][:repositories]
            repo_settings.each do |repo|
              repo[:private_key] = sshkey_path
            end
          end
        elsif token_path
          overrides[:git] ||= {}
          overrides[:git][:oauth_token] = token_path
          if repo_settings = overrides[:git][:repositories]
            repo_settings.each do |repo|
              repo[:oauth_token] = token_path
            end
          end
        elsif app_id
          overrides[:git] ||= {}
          overrides[:git][:github_app_id] = app_id
          overrides[:git][:github_app_key] = app_private_key_path
          overrides[:git][:github_app_ttl] = app_ttl
          if repo_settings = overrides[:git][:repositories]
            repo_settings.each do |repo|
              repo[:github_app_id] = app_id
              repo[:github_app_key] = app_private_key_path
              repo[:github_app_ttl] = app_ttl
            end
          end
        end

        overrides
      end
    end
  end
end
