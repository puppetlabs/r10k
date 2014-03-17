require 'r10k/cli'
require 'cri'

module R10K::CLI
  help_cmd = Cri::Command.new_basic_help
  self.command.add_command(help_cmd)
end
