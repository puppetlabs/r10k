require 'r10k'

require 'cri'

module R10K::CLI
  def self.root_command
    @cmd ||= Cri::Command.define do
      name    'r10k'
      usage   'r10k [subcommand] [options]'
      summary 'Killer robot powered Puppet environment deployment'
      description <<-EOD
        r10k is a suite of commands to help deploy and manage puppet code for
        complex environments.
      EOD

      run do |opts, args, cmd|
        puts cmd.help
      end
    end
  end
end
