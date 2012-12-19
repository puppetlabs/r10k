require 'r10k'
require 'r10k/cli'
require 'r10k/cli/environment'
require 'r10k/runner'
require 'cri'

module R10K::CLI::Environment::Cache
  def self.command
    @cmd ||= Cri::Command.define do
      name  'cache'
      usage 'cache'
      summary 'Update cache for all sources'

      run do |opts, args, cmd|
        R10K::Runner.instance.cache_sources
      end
    end
  end

  R10K::CLI::Environment.command.add_command(self.command)
end
