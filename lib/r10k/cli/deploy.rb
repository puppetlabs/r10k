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
