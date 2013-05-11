require 'r10k/cli/environment'
require 'r10k/cli/deploy'
require 'cri'

module R10K::CLI::Environment
  module Deploy
    def self.command
      @cmd ||= Cri::Command.define do
        name  'deploy'
        usage 'deploy <environment> <...>'
        summary 'DEPRECATED: Deploy an environment'

        flag :r, :recurse, 'Recursively update submodules'
        flag :u, :update, "Enable or disable cache updating"

        be_hidden

        run do |opts, args, cmd|
          logger.warn "This command is deprecated; please use `r10k deploy environment`"
          R10K::CLI::Deploy::Environment.command.block.call(opts,args,cmd)
        end
      end
    end
  end
  self.command.add_command(Deploy.command)
end
