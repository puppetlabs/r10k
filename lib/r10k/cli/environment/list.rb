require 'r10k'
require 'r10k/cli'
require 'r10k/cli/environment'
require 'r10k/runner'
require 'cri'

module R10K::CLI::Environment::List
  def self.command
    @cmd ||= Cri::Command.define do
      name  'list'
      usage 'list'
      summary 'List all available environments'

      run do |opts, args, cmd|
        output = R10K::Runner.instance.roots.inject('') do |str, root|
          str << "  - "
          str << "#{root.name}: #{root.full_path} | #{root.source}:#{root.branch}"
          str << "\n"
        end

        puts output
      end
    end
  end

  R10K::CLI::Environment.command.add_command(self.command)
end
