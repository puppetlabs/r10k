require 'r10k/cli'
require 'r10k/runner'
require 'cri'

module R10K::CLI::Deploy
  def self.command
    @cmd ||= Cri::Command.define do
      name 'deploy'
      usage 'deploy <environment>'

      run do |opts, args, cmd|
        R10K::Runner.run
      end
    end
  end
end

R10K::CLI.root_command.add_command(R10K::CLI::Deploy.command)
