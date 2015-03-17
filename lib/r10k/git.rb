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

    def self.default
      _, lib = @providers.find { |(feature, lib)| R10K::Features.available?(feature) }
      if lib.nil?
        raise R10K::Error, "No Git providers are functional."
      end
      lib
    end

    def self.provider
      @provider = default
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
  end
end
