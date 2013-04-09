require 'r10k/action/environment'
require 'r10k/action/module'
require 'r10k/cli'
require 'r10k/deployment/source'

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
          config = R10K::Deployment.config

          environments = []

          config[:sources].each_pair do |name, cfg|
            source = R10K::Deployment::Source.new(cfg[:remote], cfg[:basedir])
            environments += source.fetch_environments
          end

          stack = Middleware::Builder.new do
            environments.each do |env|
              use R10K::Action::Environment::Deploy, env
            end
          end

          # Prepare middleware environment
          stack_env = {
            :update_cache => opts[:update],
            :recurse      => opts[:recurse],
            :trace        => opts[:trace],
          }

          stack.call(stack_env)

        end
      end
    end
  end

  self.command.add_command(Deploy.command)
end
