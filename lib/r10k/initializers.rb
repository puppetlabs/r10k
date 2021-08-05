require 'r10k/logging'

require 'r10k/git'
require 'r10k/git/cache'

require 'r10k/forge/module_release'

module R10K
  module Initializers
    class BaseInitializer

      include R10K::Logging

      def initialize(settings)
        @settings = settings
      end

      private

      def with_setting(key)
        if !@settings[key].nil?
          yield @settings[key]
        end
      end
    end

    class GlobalInitializer < BaseInitializer
      def call
        with_setting(:purgedirs) do |_|
          logger.warn(_("the purgedirs key in r10k.yaml is deprecated. it is currently ignored."))
        end

        with_setting(:deploy) { |value| DeployInitializer.new(value).call }

        with_setting(:cachedir) { |value| R10K::Git::Cache.settings[:cache_root] = value }
        with_setting(:cachedir) { |value| R10K::Forge::ModuleRelease.settings[:cache_root] = value }
        with_setting(:pool_size) { |value| R10K::Puppetfile.settings[:pool_size] = value }

        with_setting(:git) { |value| GitInitializer.new(value).call }
        with_setting(:forge) { |value| ForgeInitializer.new(value).call }
      end
    end

    class DeployInitializer < BaseInitializer
      def call
        with_setting(:puppet_path) { |value| R10K::Settings.puppet_path = value }
        with_setting(:puppet_conf) { |value| R10K::Settings.puppet_conf = value }
      end
    end

    class GitInitializer < BaseInitializer
      def call
        with_setting(:provider) { |value| R10K::Git.provider = value }
        with_setting(:username) { |value| R10K::Git.settings[:username] = value }
        with_setting(:private_key) { |value| R10K::Git.settings[:private_key] = value }
        with_setting(:proxy) { |value| R10K::Git.settings[:proxy] = value }
        with_setting(:repositories) { |value| R10K::Git.settings[:repositories] = value }
        with_setting(:oauth_token) { |value| R10K::Git.settings[:oauth_token] = value }
        with_setting(:github_app_id) { |value| R10K::Git.settings[:github_app_id] = value }
        with_setting(:github_app_key) { |value| R10K::Git.settings[:github_app_key] = value }
        with_setting(:github_app_ttl) { |value| R10K::Git.settings[:github_app_ttl] = value }
      end
    end

    class ForgeInitializer < BaseInitializer
      def call
        with_setting(:baseurl) { |value| PuppetForge.host = value }
        with_setting(:proxy) { |value| PuppetForge::Connection.proxy = value }
        with_setting(:authorization_token) { |value|
          if @settings[:baseurl]
            PuppetForge::Connection.authorization = value
          else
            raise R10K::Error, "Cannot specify a Forge authorization token without configuring a custom baseurl."
          end
        }
      end
    end
  end
end
