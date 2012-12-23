require 'r10k/cli/environment'
require 'r10k/deployment'
require 'r10k/config'
require 'cri'

require 'fileutils'

module R10K::CLI::Environment::Deploy
  def self.command
    @cmd ||= Cri::Command.define do
      name  'deploy'
      usage 'deploy'
      summary 'Deploy an environment'

      run do |opts, args, cmd|
        deployment = R10K::Deployment.new(R10K::Config.instance)

        if opts[:environment]
          environments = deployment.environments.select {|env| env.name == opts[:environment]}
        else
          environments = deployment.environments
        end

        environments.each do |env|
          puts "Making environment #{env.name}"
          FileUtils.mkdir_p env.full_path
          env.sync!
        end
      end
    end
  end

  R10K::CLI::Environment.command.add_command(self.command)
end
