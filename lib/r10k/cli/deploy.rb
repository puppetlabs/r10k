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
(https://puppetlabs.com/blog/git-workflow-and-puppet-environments/).
        DESCRIPTION

        required nil, :cachedir, 'Specify a cachedir, overriding the value in config'
        flag nil, :'no-force', 'Prevent the overwriting of local module modifications'

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
`--puppetfile` flag to the command.

**NOTE**: If an environment has a Puppetfile when it is instantiated a
recursive update will be forced. It is assumed that environments are dependent
on modules specified in the Puppetfile and an update will be automatically
scheduled. On subsequent deployments, Puppetfile deployment will default to off.
          DESCRIPTION

          flag :p, :puppetfile, 'Deploy modules from a puppetfile'
          required nil, :'default-branch-override', 'Specify a branchname to override the default branch in the puppetfile'

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

          required :e, :environment, 'Update the modules in the given environment'

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

          flag :p, :puppetfile, 'Display Puppetfile modules'
          flag nil, :detail, 'Display detailed information'
          flag nil, :fetch, 'Update available environment lists from all remote sources'
          required nil, :format, 'Display output in a specific format. Valid values: json, yaml. Default: yaml'

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
