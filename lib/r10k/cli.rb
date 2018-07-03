require 'r10k'
require 'r10k/version'
require 'r10k/cli/ext/logging'
require 'r10k/logging/syslogoutputter'

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


      flag :h, :help, 'Show help for this command' do |value, cmd|
        # This is evil because we may not necessarily be called from the
        # command line and have a meaningful ARGV to scan. However the best
        # way of having a globally useful --help command is to define the
        # behavior in the block of the option to immediately handle it and exit
        # and we don't have access to the verbose option, so the simple method
        # is to simply scan ARGV.
        verbose = (ARGV.include?('-v') || ARGV.include?('--verbose'))
        puts cmd.help(:verbose => verbose)
        exit 0
      end

      flag :t, :trace, 'Display stack traces on application crash'

      loglevels = R10K::Logging::LOG_LEVELS.reverse.map(&:downcase).join(", ")
      optional :v, :verbose, "Set log verbosity. Valid values: #{loglevels}"

      flag nil, :syslog, "Send log messages to syslog."

      syslog_facilities = R10K::Logging::SyslogOutputter::SYSLOG_FACILITY_MAP.keys.map(&:downcase).join(", ")
      optional nil, :'syslog-facility', "Send log messages to this syslog facility (requires --syslog). Valid values: #{syslog_facilities}"

      flag nil, :color, 'Enable colored log messages'

      required :c, :config, 'Specify a global configuration file'

      run do |opts, args, cmd|
        puts cmd.help(:verbose => opts[:verbose])
        exit 0
      end
    end
  end
end

require 'r10k/cli/deploy'
require 'r10k/cli/puppetfile'
require 'r10k/cli/version'
require 'r10k/cli/help'
