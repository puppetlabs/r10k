require 'uri'
require 'r10k/features'
require 'r10k/errors'
require 'r10k/settings'
require 'r10k/logging'
require 'r10k/util/platform'

module R10K
  module Git
    require 'r10k/git/shellgit'
    require 'r10k/git/rugged'

    extend R10K::Logging

    # A list of Git providers, sorted by priority. Providers have features that
    # must be available for them to be used, and a module which is the namespace
    # containing the implementation.
    @providers = [
      [ :shellgit,
        {
          :feature => :shellgit,
          :module  => R10K::Git::ShellGit,
        }
      ],
      [ :rugged,
        {
          :feature => :rugged,
          :module  => R10K::Git::Rugged,
          :on_set  => proc do
            [:ssh, :https].each do |transport|
              if !::Rugged.features.include?(transport)
                logger.warn _("Rugged has been compiled without support for %{transport}; Git repositories will not be reachable via %{transport}.") % {transport: transport}
              end
            end
          end
        }
      ],
    ]

    # Mark the current provider as invalid.
    #
    # If a provider is set to an invalid provider, we need to make sure that
    # the provider doesn't fall back to the default value, thereby ignoring the
    # explicit value and silently continuing. If the current provider is
    # assigned to this value, no provider will be used until the provider is
    # either reset or assigned a valid provider.
    #
    # @api private
    NULL_PROVIDER = Object.new

    # Mark the current provider as unset.
    #
    # If the provider has never been set we need to indicate that there is no
    # current value but the default value can be used. If the current provider
    # is assigned to this value and the provider is looked up, the default
    # provider will be looked up and used.
    #
    # @api private
    UNSET_PROVIDER = Object.new

    # Return the first available Git provider.
    #
    # @raise [R10K::Error] if no Git providers are functional.
    # @return [String] The name of the first available Git implementation.
    def self.default_name
      name, _ = @providers.find { |(_, hash)| R10K::Features.available?(hash[:feature]) }
      if name.nil?
        raise R10K::Error, _("No Git providers are functional.")
      end
      name
    end

    extend R10K::Logging

    # Manually set the Git provider by name.
    #
    # @param name [Symbol] The name of the Git provider to use.
    # @raise [R10K::Error] if the requested Git provider doesn't exist.
    # @raise [R10K::Error] if the requested Git provider isn't functional.
    # @return [void]
    def self.provider=(name)
      _, attrs = @providers.find { |(providername, _)| name == providername }
      if attrs.nil?
        @provider = NULL_PROVIDER
        raise R10K::Error, _("No Git provider named '%{name}'.") % {name: name}
      end
      if !R10K::Features.available?(attrs[:feature])
        @provider = NULL_PROVIDER
        raise R10K::Error, _("Git provider '%{name}' is not functional.") % {name: name}
      end
      if attrs[:on_set]
        attrs[:on_set].call
      end

      @provider = attrs[:module]
      logger.debug1 { _("Setting Git provider to %{provider}") % {provider: @provider.name} }
    end

    # @return [Module] The namespace of the first available Git implementation.
    #   Implementation classes should be looked up against this returned Module.
    def self.provider
      case @provider
      when NULL_PROVIDER
        raise R10K::Error, _("No Git provider set.")
      when UNSET_PROVIDER
        self.provider = default_name
        logger.debug1 { _("Setting Git provider to default provider %{name}") % {name: default_name} }
      end

      @provider
    end

    def self.cache
      provider::Cache
    end

    def self.bare_repository
      provider::BareRepository
    end

    def self.thin_repository
      provider::ThinRepository
    end

    # Clear the currently set provider.
    #
    # @api private
    def self.reset!
      @provider = UNSET_PROVIDER
    end

    @provider = UNSET_PROVIDER

    extend R10K::Settings::Mixin::ClassMethods

    def_setting_attr :private_key
    def_setting_attr :oauth_token
    def_setting_attr :proxy
    def_setting_attr :username
    def_setting_attr :repositories, {}

    def self.get_repo_settings(remote)
      self.settings[:repositories].find {|r| r[:remote] == remote }
    end

    def self.get_proxy_for_remote(remote)
      # We only support proxy for HTTP(S) transport
      return nil unless remote =~ /^http(s)?/i

      repo_settings = self.get_repo_settings(remote)

      if repo_settings && repo_settings.has_key?(:proxy)
        proxy = repo_settings[:proxy] unless repo_settings[:proxy].nil? || repo_settings[:proxy].empty?
      else
        proxy = self.settings[:proxy]
      end

      R10K::Git.log_proxy_for_remote(proxy, remote) if proxy

      proxy
    end

    def self.log_proxy_for_remote(proxy, remote)
      # Sanitize passwords out of the proxy URI for loggging.
      proxy_uri = URI.parse(proxy)
      proxy_str = "#{proxy_uri.scheme}://"
      proxy_str << "#{proxy_uri.userinfo.gsub(/:(.*)$/, ':<FILTERED>')}@" if proxy_uri.userinfo
      proxy_str << "#{proxy_uri.host}:#{proxy_uri.port}"

      logger.debug { "Using HTTP proxy '#{proxy_str}' for '#{remote}'." }

      nil
    end

    # Execute block with given proxy configured in ENV
    def self.with_proxy(new_proxy)
      unless new_proxy.nil?
        old_proxy = Hash[
          ['HTTPS_PROXY', 'HTTP_PROXY', 'https_proxy', 'http_proxy'].collect do |var|
            old_value = ENV[var]
            ENV[var] = new_proxy

            [var, old_value]
          end
        ]
      end

      begin
        yield
      ensure
        ENV.update(old_proxy) if old_proxy
      end

      nil
    end
  end
end
