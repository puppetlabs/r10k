require 'r10k/cli/deploy'

require 'cri'

module R10K::CLI
  module Synchronize
    def self.command
      @cmd ||= Cri::Command.define do
        name  'synchronize'
        usage 'synchronize <options>'
        summary 'DEPRECATED: Fully synchronize all environments'

        required :c, :config, 'Specify a configuration file'

        be_hidden

        run do |opts, args, cmd|
          logger.warn "#{cmd.name} is deprecated; please use `r10k deploy environment --puppetfile`"

          opts.merge!({:puppetfile => true})
          R10K::CLI::Deploy::Environment.command.block.call(opts,args,cmd)
        end
      end
    end
  end
  self.command.add_command(Synchronize.command)
end
