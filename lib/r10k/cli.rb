require 'r10k'
require 'cri'

module R10K::CLI
  def self.command
    @cmd ||= Cri::Command.define do
      name    'r10k'
      usage   'r10k <subcommand> [options]'
      summary 'Killer robot powered Puppet environment deployment'
      description <<-EOD
        r10k is a suite of commands to help deploy and manage puppet code for
        complex environments.
      EOD

      flag :h, :help,  'show help for this command' do |value, cmd|
        puts cmd.help
        exit 0
      end

      required :c, :config, 'Specify a configuration file' do |value, cmd|
        R10K::Deployment.instance.configfile = value
      end

      run do |opts, args, cmd|
        puts cmd.help
        exit 0
      end
    end
  end
end

require 'r10k/cli/environment'
