require 'r10k/cli/environment'
require 'r10k/cli/deploy'
require 'cri'

module R10K::CLI::Environment
  module List
    def self.command
      @cmd ||= Cri::Command.define do
        name  'list'
        usage 'list'
        summary 'DEPRECATED: List all available environments'

        be_hidden

        run do |opts, args, cmd|
          logger.warn "This command is deprecated; please use `r10k deploy display`"
          R10K::CLI::Deploy::Display.command.block.call(opts,args,cmd)
        end
      end
    end
  end
  self.command.add_command(List.command)
end
