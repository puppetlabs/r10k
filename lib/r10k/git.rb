require 'r10k/features'
require 'r10k/errors'

module R10K
  module Git
    require 'r10k/git/shellgit'
    require 'r10k/git/rugged'

    @providers = [
      [:shellgit, R10K::Git::ShellGit],
      [:rugged,   R10K::Git::Rugged],
    ]

    # Return the first available Git provider.
    #
    # @raise [R10K::Error] if no Git providers are functional.
    # @return [Module] The namespace of the first available Git implementation.
    #   Implementation classes should be looked up against this returned Module.
    def self.default
      _, lib = @providers.find { |(feature, lib)| R10K::Features.available?(feature) }
      if lib.nil?
        raise R10K::Error, "No Git providers are functional."
      end
      lib
    end

    # Manually set the Git provider by name.
    #
    # @param name [Symbol] The name of the Git provider to use.
    # @raise [R10K::Error] if the requested Git provider doesn't exist.
    # @raise [R10K::Error] if the requested Git provider isn't functional.
    # @return [void]
    def self.provider=(name)
      _, lib = @providers.find { |(feature, lib)| feature == name }
      if lib.nil?
        raise R10K::Error, "No Git provider named '#{name}'."
      end
      if !R10K::Features.available?(name)
        raise R10K::Error, "Git provider '#{name}' is not functional."
      end
      @provider = lib
    end

    # @return [Module] The namespace of the first available Git implementation.
    #   Implementation classes should be looked up against this returned Module.
    def self.provider
      @provider ||= default
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
      @provider = nil
    end
  end
end
