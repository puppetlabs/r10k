require 'r10k/cli/environment'
require 'r10k/deployment'
require 'cri'

require 'fileutils'

module R10K::CLI::Environment
  module Deploy
    def self.command
      @cmd ||= Cri::Command.define do
        name  'deploy'
        usage 'deploy'
        summary 'Deploy an environment'

        flag :r, :recurse, 'Recursively update submodules'

        required :u, :update, "Enable or disable cache updating"

        run do |opts, args, cmd|
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

            if opts[:recurse]
              env.modules.each do |mod|
                mod.sync! :update_cache => update_cache
              end
            end
          end
        end
      end
    end
  end
  self.command.add_command(Deploy.command)
end
