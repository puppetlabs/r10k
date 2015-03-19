require 'r10k/features'
require 'r10k/errors'

module R10K
  module Git
    require 'r10k/git/shellgit'
    require 'r10k/git/rugged'

    # A list of Git providers, sorted by priority. Providers have features that
    # must be available for them to be used, and a module which is the namespace
    # containing the implementation.
    @providers = [
      [:shellgit, {:feature => :shellgit, :module => R10K::Git::ShellGit}],
      [:rugged,   {:feature => :rugged,   :module => R10K::Git::Rugged}],
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
    # @return [Module] The namespace of the first available Git implementation.
    #   Implementation classes should be looked up against this returned Module.
    def self.default
      _, attrs = @providers.find { |(_, hash)| R10K::Features.available?(hash[:feature]) }
      if attrs.nil?
        raise R10K::Error, "No Git providers are functional."
      end
      attrs[:module]
    end

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
      @provider = attrs[:module]
    end

    # @return [Module] The namespace of the first available Git implementation.
    #   Implementation classes should be looked up against this returned Module.
    def self.provider
      case @provider
      when NULL_PROVIDER
        raise R10K::Error, "No Git provider set."
      when UNSET_PROVIDER
        @provider = default
      else
        @provider
      end
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
  end
end
