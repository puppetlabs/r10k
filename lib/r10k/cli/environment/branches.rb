require 'r10k'
require 'r10k/cli'
require 'r10k/cli/environment'
require 'r10k/runner'
require 'cri'

module R10K::CLI::Environment::Branches
  def self.command
    @cmd ||= Cri::Command.define do
      name  'branches'
      usage 'branches'
      summary 'List all branches for a set of roots'

      run do |opts, args, cmd|

        if environment = opts[:environment]
          p R10K::Runner.instance.root(environment)
        else
        end
      end
    end
  end

  R10K::CLI::Environment.command.add_command(self.command)
end

