require 'r10k/cli'
require 'r10k/synchro/git'
require 'cri'
require 'r10k/logging'

module R10K::CLI
  module Cache
    def self.command
      @cmd ||= Cri::Command.define do
        name  'cache'
        usage 'cache'
        summary 'Update cache for all sources'

        run do |opts, args, cmd|
          sources = R10K::Deployment.config[:sources]
          remotes = Set.new

          sources.each_pair do |name, hash|
            remotes << hash['remote']
          end

          remotes.each do |remote|
            logger.info "Updating cache for #{remote.inspect}"
            synchro = R10K::Synchro::Git.new(remote)
            synchro.cache
          end
        end
      end
    end
  end
  self.command.add_command(Cache.command)
end
