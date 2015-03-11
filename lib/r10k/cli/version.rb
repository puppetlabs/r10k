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
          puts "r10k #{R10K::VERSION}"
          if opts[:verbose]
            puts RUBY_DESCRIPTION
            cmdpath = caller.last.slice(/\A.*#{$PROGRAM_NAME}/)
            puts "Command path: #{cmdpath}"
            puts "Interpreter path: #{Gem.ruby}"
            if RUBY_VERSION >= '1.9'
              puts "Default encoding: #{Encoding.default_external.name}"
            end
          end
          exit 0
        end
      end
    end
  end
  self.command.add_command(Version.command)
end
