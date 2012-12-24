require 'r10k/cli'
require 'cri'

module R10K::CLI::Module
  def self.command
    @cmd ||= Cri::Command.define do
      name  'module'
      usage 'module <subcommand>'
      summary 'Operate on a specific puppet module'

      required :e, :environment, 'Specify a particular environment'

      run do |opts, args, cmd|
        puts cmd.help
        exit 0
      end
    end
  end

  R10K::CLI.command.add_command(self.command)
end
