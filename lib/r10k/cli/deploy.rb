require 'r10k/cli'
require 'r10k/deployment'
require 'r10k/deployment/config'

require 'r10k/task_runner'
require 'r10k/task/deployment'

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

        required :c, :config, 'Specify a configuration file'

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
          summary 'deploy environments and their dependent modules'

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

          run do |opts, args, cmd|
            deploy = R10K::Deployment.load_config(opts[:config])

            task = R10K::Task::Deployment::DeployEnvironments.new(deploy)
            task.update_puppetfile = opts[:puppetfile]
            task.environment_names = args

            purge = R10K::Task::Deployment::PurgeEnvironments.new(deploy)

            runner = R10K::TaskRunner.new(:trace => opts[:trace])
            runner.append_task task
            runner.append_task purge
            runner.run

            exit runner.exit_value
          end
        end
      end
    end
    self.command.add_command(Environment.command)

    module Module
      def self.command
        @cmd ||= Cri::Command.define do
          name  'module'
          usage 'module [module] <module ...>'
          summary 'deploy modules in all environments'

          description <<-DESCRIPTION
`r10k deploy module` Deploys and updates modules inside of Puppet environments.
It will load the Puppetfile configurations out of all environments, and will
try to deploy the given module names in all environments.
          DESCRIPTION

          run do |opts, args, cmd|
            deploy = R10K::Deployment.load_config(opts[:config])

            task = R10K::Task::Deployment::DeployModules.new(deploy)
            task.module_names = args

            runner = R10K::TaskRunner.new(:trace => opts[:trace])
            runner.append_task task
            runner.run

            exit runner.exit_value
          end
        end
      end
    end
    self.command.add_command(Module.command)

    module Display
      def self.command
        @cmd ||= Cri::Command.define do
          name  'display'
          usage 'display'
          summary 'Display environments and modules in the deployment'

          flag :p, :puppetfile, 'Display Puppetfile modules'

          run do |opts, args, cmd|
            deploy = R10K::Deployment.load_config(opts[:config])

            task = R10K::Task::Deployment::Display.new(deploy)
            task.puppetfile = opts[:puppetfile]

            runner = R10K::TaskRunner.new(:trace => opts[:trace])
            runner.prepend_task task
            runner.run

            exit runner.exit_value
          end
        end
      end
    end
    self.command.add_command(Display.command)
  end
  self.command.add_command(Deploy.command)
end
