require 'r10k/cli'
require 'r10k/runner'
require 'cri'

module R10K::CLI::Deploy
  def self.command
    @cmd ||= Cri::Command.define do
      name 'deploy'
      usage 'deploy <environment>'

      flag :p, :parallel, 'Try to fetch modules in parallel.'

      run do |opts, args, cmd|
        R10K::Runner.instance.run
      end
    end
  end

  def self.run_parallel

  end

  R10K::CLI.command.add_command(self.command)
end
