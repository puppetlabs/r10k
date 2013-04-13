require 'r10k/cli'
require 'r10k/version'

require 'cri'

module R10K::CLI
  module Version
    def self.command
      @cmd ||= Cri::Command.define do
        name    'version'
        usage   'version'
        summary 'Print the version of r10k'

        run do |opts, args, cmd|
          puts R10K::VERSION
          exit 0
        end
      end
    end
  end
  self.command.add_command(Version.command)
end
