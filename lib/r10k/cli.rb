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

      # This is actually a noop action; we only add the '--trace' flag here
      # and scan for it in bin/r10k when rescuing an exception
      flag :t, :trace, 'Display stack traces on application crash'

      run do |opts, args, cmd|
        puts cmd.help
        exit 0
      end
    end
  end
end

require 'r10k/cli/environment'
require 'r10k/cli/module'
require 'r10k/cli/cache'
require 'r10k/cli/synchronize'
