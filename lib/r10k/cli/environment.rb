require 'r10k/cli'
require 'cri'

module R10K::CLI::Environment
  def self.command
    @cmd ||= Cri::Command.define do
      name  'environment'
      usage 'environment <subcommand>'
      summary 'Operate on a specific environment'

      option :e, :environment, 'Specify a particular environment', :argument => :required

      run do |opts, args, cmd|
        puts cmd.help
        exit 0
      end
    end
  end

  R10K::CLI.command.add_command(self.command)
end

require 'r10k/cli/environment/list'
require 'r10k/cli/environment/deploy'
require 'r10k/cli/environment/cache'
