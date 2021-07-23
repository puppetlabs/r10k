require 'etc'

module R10K
  module Settings
    require 'r10k/settings/container'
    require 'r10k/settings/mixin'

    require 'r10k/settings/collection'
    require 'r10k/settings/definition'
    require 'r10k/settings/list'

    class << self
      # Path to puppet executable
      attr_accessor :puppet_path
      # Path to puppet.conf
      attr_accessor :puppet_conf
    end

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

        Definition.new(:oauth_token, {
          :desc => "The path to a token file for Git OAuth remotes.
                    Only used by the 'rugged' Git provider."
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

            Definition.new(:oauth_token, {
              :desc => "The path to a token file for Git OAuth remotes.
                        Only used by the 'rugged' Git provider.",
              :default => :inherit
            }),

            URIDefinition.new(:proxy, {
              :desc => "An optional proxy server to use when interacting with Git sources via HTTP(S).",
              :default => :inherit,
            }),

            Definition.new(:ignore_branch_prefixes, {
              :desc => "Array of strings used to prefix branch names that will not be deployed as environments.",
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
        Definition.new(:authorization_token, {
          :desc => "The token for Puppet Forge authorization. Leave blank for unauthorized or license-based connections."
        })
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

        Definition.new(:purge_allowlist, {
          :desc => "A list of filename patterns to be excluded from any purge operations. Patterns are matched relative to the root of each deployed environment, if you want a pattern to match recursively you need to use the '**' glob in your pattern. Basic shell style globs are supported.",
          :default => [],
        }),

        Definition.new(:purge_whitelist, {
          :desc => "Deprecated; please use purge_allowlist instead. This setting will be removed in a future version.",
          :default => [],
        }),

        Definition.new(:generate_types, {
          :desc => "Controls whether to generate puppet types after deploying an environment. Defaults to false.",
          :default => false,
          :normalize => lambda do |input|
            input.to_s == 'true'
          end,
        }),

        Definition.new(:puppet_path, {
          :desc => "Path to puppet executable. Defaults to /opt/puppetlabs/bin/puppet.",
          :default => '/opt/puppetlabs/bin/puppet',
          :validate => lambda do |value|
            unless File.executable? value
              raise ArgumentError, "The specified puppet executable #{value} is not executable"
            end
          end
        }),
        Definition.new(:puppet_conf, {
          :desc => "Path to puppet.conf. Defaults to /etc/puppetlabs/puppet/puppet.conf.",
          :default => '/etc/puppetlabs/puppet/puppet.conf',
          :validate => lambda do |value|
            unless File.readable? value
              raise ArgumentError, "The specified puppet.conf #{value} is not readable"
            end
          end
        }),
        Definition.new(:deploy_spec, {
          :desc => "Whether or not to deploy the spec dir of a module. Defaults to false.",
          :default => false,
          :validate => lambda do |value|
            unless !!value == value
              raise ArgumentError, "`deploy_spec` can only be a boolean value, not '#{value}'"
            end
          end
        })])
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

        Definition.new(:pool_size, {
          :desc => "The amount of threads used to concurrently install modules. The default value is 1: install one module at a time.",
          :default => 4,
          :validate => lambda do |value|
            if !value.is_a?(Integer)
              raise ArgumentError, "The pool_size setting should be an integer, not a #{value.class}"
            end
            if !(value > 0)
              raise ArgumentError, "The pool_size setting should be greater than zero."
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
