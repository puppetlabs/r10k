require 'r10k/cli'
require 'r10k/cli/environment'
require 'cri'

module R10K::CLI::Environment::List
  def self.command
    @cmd ||= Cri::Command.define do
      name  'list'
      usage 'list'
      summary 'List all available environments'

      run do |opts, args, cmd|
        puts cmd.help
        exit 0
      end
    end
  end

  R10K::CLI::Environment.command.add_command(self.command)
end

