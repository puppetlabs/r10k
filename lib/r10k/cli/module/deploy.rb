require 'r10k/cli/module'
require 'r10k/deployment'
require 'cri'

require 'fileutils'

module R10K::CLI::Module::Deploy
  def self.command
    @cmd ||= Cri::Command.define do
      name  'deploy'
      usage 'deploy <module name>'
      summary 'Deploy a module'

      required :u, :update, "Enable or disable cache updating"

      run do |opts, args, cmd|

        unless (module_name = args[0])
          puts cmd.help
          exit 1
        end

        deployment = R10K::Deployment.instance
        env_list   = deployment.environments

        update_cache = (defined? opts[:update]) ? (opts[:update] == 'true') : false

        if opts[:environment]
          environments = env_list.select {|env| env.name == opts[:environment]}
        else
          environments = env_list
        end

        environments.each do |env|
          FileUtils.mkdir_p env.full_path
          env.sync! :update_cache => update_cache

          mods = env.modules.select { |mod| mod.name == module_name }

          if mods.empty?
            puts "No modules with name #{module_name} matched in environments #{env.map(&:name).inspect}".red
            exit 1
          end

          mods.each do |mod|
            mod.sync! :update_cache => update_cache
          end
        end
      end
    end
  end

  R10K::CLI::Module.command.add_command(self.command)
end
