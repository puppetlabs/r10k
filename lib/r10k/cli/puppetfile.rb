require 'r10k/cli'
require 'r10k/puppetfile'

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

          run do |opts, args, cmd|
            puppetfile_root = Dir.getwd
            puppetfile_path = ENV['PUPPETFILE_DIR']
            puppetfile      = ENV['PUPPETFILE']

            puppetfile = R10K::Puppetfile.new(puppetfile_root, puppetfile_path, puppetfile)

            runner = R10K::TaskRunner.new(opts)
            task   = R10K::Task::Puppetfile::Sync.new(puppetfile)
            runner.append_task task

            runner.run

            exit runner.exit_value
          end
        end
      end
    end
    self.command.add_command(Install.command)

    module Purge
      def self.command
        @cmd ||= Cri::Command.define do
          name  'purge'
          usage 'purge'
          summary 'Purge unmanaged modules from a Puppetfile managed directory'

          run do |opts, args, cmd|
            puppetfile_root = Dir.getwd
            puppetfile_path = ENV['PUPPETFILE_DIR']
            puppetfile      = ENV['PUPPETFILE']

            puppetfile = R10K::Puppetfile.new(puppetfile_root, puppetfile_path, puppetfile)

            runner = R10K::TaskRunner.new(opts)
            task   = R10K::Task::Puppetfile::Purge.new(puppetfile)
            runner.append_task task

            runner.run

            exit runner.exit_value
          end
        end
      end
    end
    self.command.add_command(Purge.command)
  end
  self.command.add_command(Puppetfile.command)
end
