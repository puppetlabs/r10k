require 'r10k/task'
require 'r10k/task_runner'

require 'r10k/task/environment'
require 'r10k/task/puppetfile'

require 'r10k/util/basedir'

module R10K
module Task
module Deployment
  module SharedBehaviors

    private

    def active_environments(names)

      active = []

      all_environments = @deployment.environments
      if names.empty?
        active = all_environments
      else
        # This has average case O(N^2) but N should remain relatively small, so
        # while this should be optimized that optimization can wait a while.
        names.each do |env_name|

          # Elsewhere, we sanitise the env.dirname to sub any \W to _
          # For this to match here (a single environment deploy where the 
          # branch name has \W we need to sanitise the branch name to match

          safe_branch_name = env_name.gsub(/\W/,'_')

          matching = all_environments.select do |env|
            env.dirname == safe_branch_name
          end

          if matching.empty?
            logger.warn "Environment #{env_name} not found in any source"
            task_runner.succeeded = false
          else
            active.concat(matching)
          end
        end
      end

      active.reverse
    end

    # @param [Array<String>] names The list of environments to deploy.
    #
    def with_environments(names = [])
      active_environments(names).each do |env|
        yield env
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

    # @!attribute update_puppetfile_if_changed
    #   @return [TrueClass, FalseClass] Whether to deploy modules in a puppetfile if the environment changed since last deploy
    attr_accessor :update_puppetfile_if_changed

    def initialize(deployment)
      @deployment = deployment
      @update_puppetfile = false
      @update_puppetfile_if_changed = false
      @environment_names = []
    end

    def call
      @deployment.preload!

      with_environments(@environment_names) do |env|
        task = R10K::Task::Environment::Deploy.new(env)
        task.update_puppetfile = @update_puppetfile
        task.update_puppetfile_if_changed = @update_puppetfile_if_changed
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
      @basedirs   = @deployment.sources.map { |x| x.basedir }.uniq
    end

    def call
      @basedirs.each do |path|
        basedir = R10K::Util::Basedir.from_deployment(path, @deployment)
        logger.info "Purging stale environments from #{path}"
        basedir.purge!
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

