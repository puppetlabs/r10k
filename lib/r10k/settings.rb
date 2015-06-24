require 'etc'

module R10K
  module Settings
    require 'r10k/settings/container'
    require 'r10k/settings/mixin'

    require 'r10k/settings/collection'
    require 'r10k/settings/definition'

    def self.git_settings
      R10K::Settings::Collection.new(:git, [

        EnumDefinition.new(:provider, {
          :desc => "The Git provider to use. Valid values: 'shellgit', 'rugged'",
          :normalize => lambda { |input| input.to_sym },
          :enum => [:shellgit, :rugged],
        }),

        Definition.new(:username, {
          :desc => "The username to use for Git SSH remotes that do not specify a user.
                    Only used by the 'rugged' Git provider.
                    Default: the current user",
          :default => lambda { Etc.getlogin },
        }),

        Definition.new(:private_key, {
          :desc => "The path to the SSH private key for Git SSH remotes.
                    Only used by the 'rugged' Git provider.",
        })
      ])
    end

    def self.forge_settings
      R10K::Settings::Collection.new(:forge, [
        URIDefinition.new(:proxy, {
          :desc => "An optional proxy server to use when downloading modules from the forge.",
        }),

        URIDefinition.new(:baseurl, {
          :desc => "The URL to the Puppet Forge to use for downloading modules."
        }),
      ])
    end
  end
end
