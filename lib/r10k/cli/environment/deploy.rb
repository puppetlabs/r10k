require 'r10k/cli/environment'
require 'r10k/deployment'
require 'r10k/action'

require 'cri'
require 'middleware'

module R10K::CLI::Environment
  module Deploy
    def self.command
      @cmd ||= Cri::Command.define do
        name  'deploy'
        usage 'deploy <environment> <...>'
        summary 'Deploy an environment'

        flag :r, :recurse, 'Recursively update submodules'
        flag :u, :update, "Enable or disable cache updating"

        run do |opts, args, cmd|
          deployment = R10K::Deployment.instance
          env_list   = deployment.environments

          if not args.empty?
            environments = env_list.select {|env| args.include? env.name }
          else
            environments = env_list
          end

          stack = Middleware::Builder.new do
            environments.each do |env|
              use R10K::Action::Environment::Deploy, env
            end
          end

          # Prepare middleware environment
          stack_env = {
            :update_cache => (opts[:update] == 'true'),
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
