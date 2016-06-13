require 'etc'

module R10K
  module Settings
    require 'r10k/settings/container'
    require 'r10k/settings/mixin'

    require 'r10k/settings/collection'
    require 'r10k/settings/definition'
    require 'r10k/settings/list'

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

        URIDefinition.new(:proxy, {
          :desc => "An optional proxy server to use when interacting with Git sources via HTTP(S).",
          :default => :inherit,
        }),

        List.new(:repositories, lambda {
          R10K::Settings::Collection.new(nil, [
            Definition.new(:remote, {
              :desc => "Remote source that repository-specific settings should apply to.",
            }),

            Definition.new(:private_key, {
              :desc => "The path to the SSH private key for Git SSH remotes.
                        Only used by the 'rugged' Git provider.",
              :default => :inherit,
            }),

            URIDefinition.new(:proxy, {
              :desc => "An optional proxy server to use when interacting with Git sources via HTTP(S).",
              :default => :inherit,
            }),
          ])
        },
        {
          :desc => "Repository specific configuration.",
          :default => [],
        }),
      ])
    end

    def self.forge_settings
      R10K::Settings::Collection.new(:forge, [
        URIDefinition.new(:proxy, {
          :desc => "An optional proxy server to use when downloading modules from the forge.",
          :default => :inherit,
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

        EnumDefinition.new(:purge_levels, {
          :desc => "Controls how aggressively r10k will purge unmanaged content from the target directory. Should be a list of values indicating at what levels unmanaged content should be purged. Options are 'deployment', 'environment', and 'puppetfile'. For backwards compatibility, the default is ['deployment', 'puppetfile'].",
          :multi => true,
          :enum => [:deployment, :environment, :puppetfile],
          :default => [:deployment, :puppetfile],
          :normalize => lambda do |input|
            if input.respond_to?(:collect)
              input.collect { |val| val.to_sym }
            else
              # Convert single values to a list of one symbolized value.
              [input.to_sym]
            end
          end,
        }),

        Definition.new(:purge_whitelist, {
          :desc => "A list of filename patterns to be excluded from any purge operations. Patterns are matched relative to the root of each deployed environment, if you want a pattern to match recursively you need to use the '**' glob in your pattern. Basic shell style globs are supported.",
          :default => [],
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

        URIDefinition.new(:proxy, {
          :desc => "Proxy to use for all r10k operations which occur over HTTP(S).",
          :default => lambda {
            [
              ENV['HTTPS_PROXY'],
              ENV['https_proxy'],
              ENV['HTTP_PROXY'],
              ENV['http_proxy']
            ].find { |value| value }
          },
        }),

        R10K::Settings.forge_settings,

        R10K::Settings.git_settings,

        R10K::Settings.deploy_settings,
      ])
    end
  end
end
