require 'r10k/features'
require 'r10k/errors'
require 'r10k/settings'
require 'r10k/logging'

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
                logger.warn "Rugged has been compiled without support for #{transport}; Git repositories will not be reachable via #{transport}."
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
        raise R10K::Error, "No Git providers are functional."
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
        raise R10K::Error, "No Git provider named '#{name}'."
      end
      if !R10K::Features.available?(attrs[:feature])
        @provider = NULL_PROVIDER
        raise R10K::Error, "Git provider '#{name}' is not functional."
      end
      if attrs[:on_set]
        attrs[:on_set].call
      end

      @provider = attrs[:module]
      logger.debug1 { "Setting Git provider to #{@provider.name}" }
    end

    # @return [Module] The namespace of the first available Git implementation.
    #   Implementation classes should be looked up against this returned Module.
    def self.provider
      case @provider
      when NULL_PROVIDER
        raise R10K::Error, "No Git provider set."
      when UNSET_PROVIDER
        self.provider = default_name
        logger.debug1 { "Setting Git provider to default provider #{default_name}" }
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
    def_setting_attr :username
    def_setting_attr :repositories, {}
  end
end
