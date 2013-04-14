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

          flag :p, :puppetfile, 'Deploy modules from a puppetfile'

          run do |opts, args, cmd|
            config = R10K::Config.new(opts[:config])
            deploy = R10K::Deployment.new(config)

            environments = deploy.environments.inject({}) do |hash, env|
              hash[env.dirname] = env
              hash
            end

            env_names = args.empty? ? environments.keys : args

            env_names.each do |env_name|
              logger.notice "Deploying environment #{env_name}"
              if (env = environments[env_name])
                env.sync
                if opts[:puppetfile]
                  env.modules.each do |mod|
                    logger.notice "Deploying module #{mod.name} in #{env_name}"
                    mod.sync
                  end
                end
              else
                logger.warn "Environment #{env_name} not found in any source"
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
