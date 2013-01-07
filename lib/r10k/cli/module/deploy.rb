require 'r10k/cli/module'
require 'r10k/deployment'
require 'cri'

require 'fileutils'

module R10K::CLI::Module
  module Deploy
    def self.command
      @cmd ||= Cri::Command.define do
        name  'deploy'
        usage 'deploy [module name] <module name> ...'
        summary 'Deploy a module'

        flag :u, :update, "Update module cache"

        run do |opts, args, cmd|

          unless (module_name = args[0])
            puts cmd.help
            exit 1
          end

          env_list = R10K::Deployment.instance.environments

          if opts[:environment]
            environments = env_list.select {|env| env.name == opts[:environment]}
          else
            environments = env_list
          end

          environments.each do |env|
            mods = env.modules.select { |mod| mod.name == module_name }

            if mods.empty?
              puts "No modules with name #{module_name} matched in environments #{environments.map(&:name).inspect}".red
              exit 1
            end

            stack = Middleware::Builder.new
            mods.each { |mod| stack.use R10K::Action::Module::Deploy, mod }

            stack_env = {
              :update_cache => opts[:update],
              :trace        => opts[:trace],
            }

            stack.call(stack_env)
          end
        end
      end
    end
  end
  self.command.add_command(Deploy.command)
end
