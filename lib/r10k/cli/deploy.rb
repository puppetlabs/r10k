require 'r10k/cli'
require 'r10k/deployment'
require 'r10k/deployment/config'

require 'cri'
require 'middleware'

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
          usage   'environment <environment> <...>'
          summary 'deploy an environment'

          run do |opts, args, cmd|
            config = R10K::Config.new(opts[:config])
            deploy = R10K::Deployment.new(config)

            envs = deploy.environments.inject({}) do |hash, env|
              hash[env.dirname] = env
              hash
            end

            if args.empty?
              logger.notice "Deploying environments #{envs.keys.join(', ')}"
              envs.values.each do |env|
                env.sync
              end
            else
              args.each do |arg|
                if (env = envs[arg])
                  logger.notice "Deploying environment #{arg}"
                  env.sync
                else
                  logger.warn "Environment #{arg} not found in any source"
                end
              end
            end

            exit 0
          end
        end
      end
    end
    self.command.add_command(Environment.command)
  end
  self.command.add_command(Deploy.command)
end
