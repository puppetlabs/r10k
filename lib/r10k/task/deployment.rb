require 'r10k/task'
require 'r10k/task_runner'

require 'r10k/task/environment'
require 'r10k/task/puppetfile'

module R10K
module Task
module Deployment
  module SharedBehaviors

    private

    def load_environments!
      @environments = @deployment.environments.inject({}) do |hash, env|
        hash[env.dirname] = env
        hash
      end
    end

    # @param [Array<String>] names The list of environments to deploy.
    #
    def with_environments(names = [], &block)
      load_environments!

      # If an explicit list of environments were not given, deploy everything
      if names.size > 0
        to_deploy = names
      else
        to_deploy = @environments.keys
      end

      to_deploy.each do |env_name|
        if (env = @environments[env_name])
          yield env
        else
          logger.warn "Environment #{env_name} not found in any source"
          task_runner.succeeded = false
        end
      end
    end
  end

  class DeployEnvironments < R10K::Task::Base

    include SharedBehaviors

    # @!attribute environment_names
    #   @return [Array<String>] A list of environments to deploy, by name.
    attr_accessor :environment_names

    # @!attribute update_puppetfile
    #   @return [TrueClass, FalseClass] Whether to deploy modules in a puppetfile
    attr_accessor :update_puppetfile

    def initialize(deployment)
      @deployment = deployment
      @update_puppetfile = false
      @environment_names = []
    end

    def call
      logger.info "Loading environments from all sources"
      @deployment.fetch_sources

      with_environments(@environment_names) do |env|
        task = R10K::Task::Environment::Deploy.new(env)
        task.update_puppetfile = @update_puppetfile
        task_runner.insert_task_after(self, task)
      end
    end
  end

  class DeployModules < R10K::Task::Base

    include SharedBehaviors

    attr_accessor :module_names

    # @!attribute environment_names
    #   @return [Array<String>] A list of environments to update modules
    attr_accessor :environment_names

    def initialize(deployment)
      @deployment        = deployment
      @environment_names = []
    end

    def call
      with_environments(@environment_names) do |env|
        puppetfile = env.puppetfile

        task = R10K::Task::Puppetfile::DeployModules.new(puppetfile)
        task.module_names = module_names

        task_runner.insert_task_after(self, task)
      end
    end
  end

  class PurgeEnvironments < R10K::Task::Base

    def initialize(deployment)
      @deployment = deployment
    end

    def call
      @deployment.sources.each do |source|
        stale_envs = source.stale_contents

        dir = source.managed_directory

        if stale_envs.empty?
          logger.debug "No stale environments in #{dir}"
        else
          logger.info "Purging stale environments from #{dir}"
          logger.debug "Stale modules in #{dir}: #{stale_envs.join(', ')}"
          source.purge!
        end
      end
    end
  end

  class Display < R10K::Task::Base

    attr_accessor :puppetfile

    def initialize(deployment)
      @deployment = deployment
    end

    def call
      @deployment.environments.each do |env|

        puts "  - #{env.dirname}"

        if @puppetfile
          puppetfile = env.puppetfile
          puppetfile.load

          puppetfile.modules.each do |mod|
            puts "    - #{mod.name} (#{mod.version})"
          end
        end
      end
    end
  end
end
end
end

