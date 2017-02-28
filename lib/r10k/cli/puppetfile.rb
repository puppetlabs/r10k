require 'r10k/cli'
require 'r10k/puppetfile'
require 'r10k/action/puppetfile'

require 'cri'

module R10K::CLI
  module Puppetfile
    def self.command
      @cmd ||= Cri::Command.define do
        name    'puppetfile'
        usage   'puppetfile <subcommand>'
        summary 'Perform operations on a Puppetfile'

        description <<-DESCRIPTION
`r10k puppetfile` provides an implementation of the librarian-puppet style
Puppetfile (http://bombasticmonkey.com/librarian-puppet/).
        DESCRIPTION

        run do |opts, args, cmd|
          puts cmd.help(:verbose => opts[:verbose])
          exit 0
        end
      end
    end

    module Install
      def self.command
        @cmd ||= Cri::Command.define do
          name    'install'
          usage   'install'
          summary 'Install all modules from a Puppetfile'

          required nil, :moduledir, 'Path to install modules to (can also be set with PUPPETFILE_DIR environment variable)'
          required nil, :puppetfile, 'Path to Puppetfile (can also be set with PUPPETFILE environment variable)'
          flag :f, :update_force, 'Force locally changed files to be overwritten'
          # @todo add --no-purge option
          runner R10K::Action::Puppetfile::CriRunner.wrap(R10K::Action::Puppetfile::Install)
        end
      end
    end

    module Check
      def self.command
        @cmd ||= Cri::Command.define do
          name  'check'
          usage 'check'
          summary 'Try and load the Puppetfile to verify the syntax is correct.'

          required nil, :puppetfile, 'Path to Puppetfile (can also be set with PUPPETFILE environment variable)'
          runner R10K::Action::Puppetfile::CriRunner.wrap(R10K::Action::Puppetfile::Check)
        end
      end
    end

    module Purge
      def self.command
        @cmd ||= Cri::Command.define do
          name  'purge'
          usage 'purge'
          summary 'Purge unmanaged modules from a Puppetfile managed directory'

          required nil, :moduledir, 'Path to install modules to (can also be set with PUPPETFILE_DIR environment variable)'
          required nil, :puppetfile, 'Path to Puppetfile (can also be set with PUPPETFILE environment variable)'
          runner R10K::Action::Puppetfile::CriRunner.wrap(R10K::Action::Puppetfile::Purge)
        end
      end
    end
  end
end

R10K::CLI.command.add_command(R10K::CLI::Puppetfile.command)

R10K::CLI::Puppetfile.command.add_command(R10K::CLI::Puppetfile::Install.command)
R10K::CLI::Puppetfile.command.add_command(R10K::CLI::Puppetfile::Check.command)
R10K::CLI::Puppetfile.command.add_command(R10K::CLI::Puppetfile::Purge.command)
