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

        run do |opts, args, cmd|
          # TODO delegate the default invocation to synchronize
          puts cmd.help
          exit 0
        end
      end
    end

    module Environment
      def self.command
        @cmd ||= Cri::Command.define do
          name    'environment'
          usage   'environment <options> <environment> <...>'
          summary 'deploy an environment'

          flag :p, :puppetfile, 'Deploy modules from a puppetfile'

          run do |opts, args, cmd|
            config = R10K::Config.new(opts[:config])
            deploy = R10K::Deployment.new(config)

            task   = R10K::Task::Deployment::DeployEnvironments.new(deploy)
            task.update_puppetfile = opts[:puppetfile]
            task.environment_names = args

            runner = R10K::TaskRunner.new(:trace => opts[:trace])
            runner.add_task task
            runner.run

            exit runner.exit_value
          end
        end
      end
    end
    self.command.add_command(Environment.command)
  end
  self.command.add_command(Deploy.command)
end
