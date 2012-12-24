require 'r10k/cli/environment'
require 'r10k/deployment'
require 'cri'

require 'fileutils'

module R10K::CLI::Environment::Deploy
  def self.command
    @cmd ||= Cri::Command.define do
      name  'deploy'
      usage 'deploy'
      summary 'Deploy an environment'

      flag :r, :recurse, 'Recursively update submodules'

      flag :u, :update, "Don't update module cache data"

      run do |opts, args, cmd|
        deployment = R10K::Deployment.instance
        env_list   = deployment.environments

        update_cache = (defined? opts[:update]) ? opts[:update] : true

        if opts[:environment]
          environments = env_list.select {|env| env.name == opts[:environment]}
        else
          environments = env_list
        end

        environments.each do |env|
          puts "Synchronizing environment #{env.name}"
          FileUtils.mkdir_p env.full_path
          env.sync! :update_cache => update_cache
        end
      end
    end
  end

  R10K::CLI::Environment.command.add_command(self.command)
end
