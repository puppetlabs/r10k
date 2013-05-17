require 'r10k/cli/module'
require 'r10k/cli/deploy'
require 'cri'

module R10K::CLI::Module
  module List
    def self.command
      @cmd ||= Cri::Command.define do
        name  'list'
        usage 'list'
        summary 'DEPRECATED: List modules that are instantiated in environments'

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

