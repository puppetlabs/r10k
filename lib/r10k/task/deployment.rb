require 'r10k/task'
require 'r10k/task_runner'

require 'r10k/task/environment'

module R10K
module Task
module Deployment
  class DeployEnvironments < R10K::Task::Base

    # @!attrubte names
    #   @return [Array<String>] A list of environments to deploy, by name.
    attr_accessor :names

    # @!attribute puppetfile
    #   @return [TrueClass, FalseClass] Whether to deploy modules in a puppetfile
    attr_accessor :puppetfile

    def initialize(deployment, opts = {})
      @deployment = deployment

      @names      = opts.delete(:environments) || []
      @puppetfile = opts.delete(:puppetfile)

      raise "Unrecognized options: #{opts.keys.join(', ')}" unless opts.empty?
    end

    def call
      logger.info "Loading environments from all sources"

      load_environments!

      # If an explicit list of environments were not given, deploy everything
      if @names.size > 0
        to_deploy = names
      else
        to_deploy = @environments.keys
      end

      to_deploy.each do |env_name|
        if (env = @environments[env_name])
          task = R10K::Task::Environment::Deploy.new(env, :puppetfile => @puppetfile)
          task_runner.add_task task
        else
          logger.warn "Environment #{env_name} not found in any source"
          task_runner.succeeded = false
        end
      end
    end

    private

    def load_environments!
      @environments = @deployment.environments.inject({}) do |hash, env|
        hash[env.dirname] = env
        hash
      end
    end
  end
end
end
end

