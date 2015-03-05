require 'r10k/features'
require 'r10k/errors'

module R10K
  module Git
    require 'r10k/git/errors'

    require 'r10k/git/ref'
    require 'r10k/git/tag'
    require 'r10k/git/head'
    require 'r10k/git/remote_head'
    require 'r10k/git/commit'

    require 'r10k/git/repository'
    require 'r10k/git/cache'
    require 'r10k/git/alternates'
    require 'r10k/git/working_dir'

    require 'r10k/git/shellgit'

    @providers = {:shellgit => R10K::Git::ShellGit}

    def self.default
      if R10K::Features.available?(:shellgit)
        @providers[:shellgit]
      else
        raise R10K::Error, "No Git providers are functional"
      end
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
