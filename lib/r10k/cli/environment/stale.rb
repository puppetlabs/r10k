require 'r10k/cli/environment'
require 'r10k/deployment'
require 'cri'

module R10K::CLI::Environment
  module Stale
    def self.command
      @cmd ||= Cri::Command.define do
        name  'stale'
        usage 'stale <directory> [directory ...]'
        summary 'REMOVED: List all stale environments'

        description "This command has been removed in 1.0.0"
        be_hidden

        run do |opts, args, cmd|
          $stderr.puts "#{cmd.name} has been removed in 1.0.0"
          exit 1
        end
      end
    end
  end
  self.command.add_command(Stale.command)
end
