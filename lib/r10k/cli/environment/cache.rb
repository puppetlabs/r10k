require 'r10k/cli/environment'
require 'r10k/synchro/git'
require 'cri'

module R10K::CLI::Environment::Cache
  def self.command
    @cmd ||= Cri::Command.define do
      name  'cache'
      usage 'cache'
      summary 'Update cache for all sources'

      run do |opts, args, cmd|
        R10K::Deployment.instance[:sources].each_pair do |name, source|
          synchro = R10K::Synchro::Git.new(source)
          synchro.cache
        end
      end
    end
  end

  R10K::CLI::Environment.command.add_command(self.command)
end
