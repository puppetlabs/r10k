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
        }),

        Definition.new(:repositories, {
        :desc => "Repository specific configuration.",
        :default => [],
        :normalize => lambda do |repositories|
        # The config file loading logic recursively converts hash keys that are strings to symbols,
        # It doesn't understand hashes inside arrays though so we have to do this manually.
          repositories.map do |repo|
            repo.inject({}) do |retval, (key, value)|
              retval[key.to_sym] = value
              retval
            end
          end
        end
      }),
      ])
    end

    def self.forge_settings
      R10K::Settings::Collection.new(:forge, [
        URIDefinition.new(:proxy, {
          :desc => "An optional proxy server to use when downloading modules from the forge.",
          :default => lambda do
            [
              ENV['HTTPS_PROXY'],
              ENV['https_proxy'],
              ENV['HTTP_PROXY'],
              ENV['http_proxy']
            ].find { |value| value }
          end
        }),

        URIDefinition.new(:baseurl, {
          :desc => "The URL to the Puppet Forge to use for downloading modules."
        }),
      ])
    end

    def self.deploy_settings
      R10K::Settings::Collection.new(:deploy, [
        Definition.new(:write_lock, {
          :desc => "Whether r10k deploy actions should be locked out in case r10k is being managed
          by another application. The value should be a string containing the reason for the write lock.",
          :validate => lambda do |value|
            if value && !value.is_a?(String)
              raise ArgumentError, "The write_lock setting should be a string containing the reason for the write lock, not a #{value.class}"
            end
          end
        }),
      ])
    end

    def self.global_settings
      R10K::Settings::Collection.new(:global, [
        Definition.new(:sources, {
          :desc => "Where r10k should retrieve sources when deploying environments.
                    Only used for r10k environment deployment.",
        }),

        Definition.new(:purgedirs, {
          :desc => "The purgedirs setting was deprecated in r10k 1.0.0 and is no longer respected.",
        }),

        Definition.new(:cachedir, {
          :desc => "Where r10k should store cached Git repositories.",
        }),

        Definition.new(:postrun, {
          :desc => "The command r10k should run after deploying environments.",
          :validate => lambda do |value|
            if !value.is_a?(Array)
              raise ArgumentError, "The postrun setting should be an array of strings, not a #{value.class}"
            end
          end
        }),

        R10K::Settings.forge_settings,

        R10K::Settings.git_settings,

        R10K::Settings.deploy_settings,
      ])
    end
  end
end
