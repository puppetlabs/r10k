require 'r10k/cli'
require 'r10k/deployment'
require 'r10k/action/environment'

require 'middleware'
require 'cri'

module R10K::CLI
  module Synchronize
    def self.command
      @cmd ||= Cri::Command.define do
        name  'synchronize'
        usage 'synchronize <options>'
        summary 'Fully synchronize all environments'

        flag :u, :update, "Update cache before running"

        run do |opts, args, cmd|
          deployment   = R10K::Deployment.instance
          environments = deployment.environments
          directories  = (deployment.config[:purgedirs] || [])

          stack = Middleware::Builder.new do
            environments.each do |env|
              use R10K::Action::Environment::Deploy, env
            end

            directories.each do |dir|
              use R10K::Action::Environment::Purge, dir
            end
          end

          stack_env = {
            :update_cache => opts[:update],
            :trace        => opts[:trace],
            :recurse      => true,
          }

          stack.call(stack_env)
        end
      end
    end
  end
  self.command.add_command(Synchronize.command)
end
