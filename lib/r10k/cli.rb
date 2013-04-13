require 'r10k'
require 'r10k/logging'
require 'r10k/version'
require 'r10k/cli/ext/logging'

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
        R10K::Deployment.config.configfile = value
      end

      required :v, :verbose, 'Set verbosity level' do |value, cmd|
        R10K::Logging.level = Integer(value)
      end

      flag :t, :trace,   'Display stack traces on application crash'
      # TODO remove short option when cri can support it
      flag :e, :version, 'Print the R10K version'

      run do |opts, args, cmd|
        if opts[:version]
          puts R10K::VERSION
        else
          puts cmd.help
        end
        exit 0
      end
    end
  end
end

require 'r10k/cli/deploy'
require 'r10k/cli/environment'
require 'r10k/cli/module'
require 'r10k/cli/cache'
require 'r10k/cli/synchronize'
