require 'r10k/cli/environment'
require 'r10k/deployment'
require 'cri'

module R10K::CLI::Environment
  module Stale
    def self.command
      @cmd ||= Cri::Command.define do
        name  'stale'
        usage 'stale <directory> [directory ...]'
        summary 'List all stale environments'

        run do |opts, args, cmd|
          deployment = R10K::Deployment.instance

          if args.empty?
            $stderr.print "ERROR: ".red
            $stderr.puts "#{cmd.name} requires one or more directories"
            $stderr.puts cmd.help
            exit(1)
          end

          args.each do |dir|
            puts "Stale environments in #{dir}:"
            output = deployment.collection.stale(dir).each do |stale_dir|
              puts "  - #{stale_dir}"
            end
          end
        end
      end
    end
  end
  self.command.add_command(Stale.command)
end
