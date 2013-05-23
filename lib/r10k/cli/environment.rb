require 'r10k/cli'
require 'cri'

module R10K::CLI
  module Environment
    def self.command
      @cmd ||= Cri::Command.define do
        name  'environment'
        usage 'environment <subcommand>'
        summary 'DEPRECATED: Operate on a specific environment'

        required :c, :config, 'Specify a configuration file'

        be_hidden

        run do |opts, args, cmd|
          puts cmd.help(:verbose => opts[:verbose])
          exit 0
        end
      end
    end
  end
  self.command.add_command(Environment.command)
end

require 'r10k/cli/environment/list'
require 'r10k/cli/environment/deploy'
require 'r10k/cli/environment/stale'
