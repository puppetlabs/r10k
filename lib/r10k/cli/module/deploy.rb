require 'r10k/cli/module'
require 'r10k/deployment'
require 'r10k/logging'
require 'cri'

require 'fileutils'

module R10K::CLI::Module
  module Deploy
    def self.command
      @cmd ||= Cri::Command.define do
        name  'deploy'
        usage 'deploy [module name] <module name> ...'
        summary 'DEPRECATED: Deploy a module'

        be_hidden

        flag :u, :update, "Update module cache"

        run do |opts, args, cmd|
          logger.warn "This command is deprecated; please use `r10k deploy module`"
          R10K::CLI::Deploy::Module.command.block.call(opts,args,cmd)
        end
      end
    end
  end
  self.command.add_command(Deploy.command)
end
