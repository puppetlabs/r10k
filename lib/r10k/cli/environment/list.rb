require 'r10k/cli/environment'
require 'r10k/deployment'
require 'cri'

module R10K::CLI::Environment
  module List
    def self.command
      @cmd ||= Cri::Command.define do
        name  'list'
        usage 'list'
        summary 'List all available environments'

        run do |opts, args, cmd|
          deployment = R10K::Deployment.new(R10K::Config.instance)
          output = deployment.environments.inject('') do |str, root|
            str << "  - "
            str << "#{root.name}: #{root.full_path}"
            str << "\n"
          end

          puts output
        end
      end
    end
  end
  self.command.add_command(List.command)
end
