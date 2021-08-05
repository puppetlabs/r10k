require 'r10k/cli'
require 'r10k/deployment'
require 'r10k/deployment/config'

require 'r10k/action/cri_runner'
require 'r10k/action/deploy'


require 'cri'

module R10K::CLI
  module Deploy
    def self.command
      @cmd ||= Cri::Command.define do
        name    'deploy'
        usage   'deploy <subcommand>'
        summary 'Puppet dynamic environment deployment'

        description <<-DESCRIPTION
`r10k deploy` implements the Git branch to Puppet environment workflow
(https://puppet.com/docs/puppet/latest/environments_about.html).
        DESCRIPTION

        option nil, :cachedir, 'Specify a cachedir, overriding the value in config', argument: :required
        flag nil, :'no-force', 'Prevent the overwriting of local module modifications'
        flag nil, :'generate-types', 'Run `puppet generate types` after updating an environment'
        flag nil, :'deploy-spec', 'Deploy the spec dir alongside other module directories'
        option nil, :'puppet-path', 'Path to puppet executable', argument: :required do |value, cmd|
          unless File.executable? value
            $stderr.puts "The specified puppet executable #{value} is not executable."
            puts cmd.help
            exit 1
          end
        end
        option nil, :'puppet-conf', 'Path to puppet.conf', argument: :required
        option nil, :'private-key', 'Path to SSH key to use when cloning. Only valid with rugged provider', argument: :required
        option nil, :'oauth-token', 'Path to OAuth token to use when cloning. Only valid with rugged provider', argument: :required
        option nil, :'github-app-id', 'Github App id. Only valid with rugged provider', argument: :required
        option nil, :'github-app-key', 'Github App private key. Only valid with rugged provider', argument: :required
        option nil, :'github-app-ttl', 'Github App token expiration, in seconds. Only valid with rugged provider', default: "120", argument: :optional

        run do |opts, args, cmd|
          puts cmd.help(:verbose => opts[:verbose])
          exit 0
        end
      end
    end

    module Environment
      def self.command
        @cmd ||= Cri::Command.define do
          name    'environment'
          usage   'environment <options> <environment> <...>'
          summary 'Deploy environments and their dependent modules'

          description <<-DESCRIPTION
`r10k deploy environment` creates and updates Puppet environments based on Git
branches.

Environments can provide a Puppetfile at the root of the directory to deploy
independent Puppet modules. To recursively deploy an environment, pass the
`--modules` flag to the command.

**NOTE**: If an environment has a Puppetfile when it is instantiated a
recursive update will be forced. It is assumed that environments are dependent
on modules specified in the Puppetfile and an update will be automatically
scheduled. On subsequent deployments, Puppetfile deployment will default to off.
          DESCRIPTION

          flag :p, :puppetfile, 'Deploy modules (deprecated, use -m)'
          flag :m, :modules, 'Deploy modules'
          option nil, :'default-branch-override', 'Specify a branchname to override the default branch in the puppetfile',
                 argument: :required

          runner R10K::Action::CriRunner.wrap(R10K::Action::Deploy::Environment)
        end
      end
    end

    module Module
      def self.command
        @cmd ||= Cri::Command.define do
          name  'module'
          usage 'module [module] <module ...>'
          summary 'Deploy modules in all environments'

          description <<-DESCRIPTION
`r10k deploy module` Deploys and updates modules inside of Puppet environments.
It will load the Puppetfile configurations out of all environments, and will
try to deploy the given module names in all environments.
          DESCRIPTION

          option :e, :environment, 'Update the modules in the given environment', argument: :required

          runner R10K::Action::CriRunner.wrap(R10K::Action::Deploy::Module)
        end
      end
    end

    module Display
      def self.command
        @cmd ||= Cri::Command.define do
          name  'display'
          aliases 'list'
          usage 'display'
          summary 'Display environments and modules in the deployment'

          flag :p, :puppetfile, 'Display modules (deprecated, use -m)'
          flag :m, :modules, 'Display modules'
          flag nil, :detail, 'Display detailed information'
          flag nil, :fetch, 'Update available environment lists from all remote sources'
          option nil, :format, 'Display output in a specific format. Valid values: json, yaml. Default: yaml',
                 argument: :required

          runner R10K::Action::CriRunner.wrap(R10K::Action::Deploy::Display)
        end
      end
    end
  end
end

R10K::CLI.command.add_command(R10K::CLI::Deploy.command)
R10K::CLI::Deploy.command.add_command(R10K::CLI::Deploy::Environment.command)
R10K::CLI::Deploy.command.add_command(R10K::CLI::Deploy::Module.command)
R10K::CLI::Deploy.command.add_command(R10K::CLI::Deploy::Display.command)
