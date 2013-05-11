require 'r10k/task'
require 'r10k/task/module'

require 'r10k/task_runner'

module R10K
module Task
module Puppetfile
  class Sync < R10K::Task::Base
    def initialize(puppetfile)
      @puppetfile = puppetfile
    end

    def call
      logger.info "Loading modules from Puppetfile into queue"

      @puppetfile.load
      @puppetfile.modules.each do |mod|
        task = R10K::Task::Module::Sync.new(mod)
        task_runner.insert_task_after(self, task)
      end

      purge_task = Purge.new(@puppetfile)
      task_runner.append_task purge_task
    end
  end

  class DeployModules < R10K::Task::Base

    attr_accessor :module_names

    def initialize(puppetfile)
      @puppetfile = puppetfile
    end

    def call
      logger.debug "Updating module list for Puppetfile #{@puppetfile.basedir}"
      @puppetfile.load
      load_modulemap!

      existing = @modulemap.keys

      warn_on_missing(existing, @module_names)

      to_deploy = existing & @module_names

      to_deploy.each do |mod_name|
        mod = @modulemap[mod_name]
        task = R10K::Task::Module::Sync.new(mod)
        task_runner.insert_task_after(self, task)
      end
    end

    private

    def warn_on_missing(existing, requested)
      missing_modules = requested - existing

      unless missing_modules.empty?
        task_runner.succeeded = false

        missing_modules.each do |missing|
          logger.warn "Unable to deploy module #{missing}: not listed in #{@puppetfile.puppetfile_path}"
        end
      end
    end

    def load_modulemap!
        @modulemap = @puppetfile.modules.inject({}) do |hash, mod|
        hash[mod.name] = mod
        hash
      end
    end
  end

  class Purge < R10K::Task::Base
    def initialize(puppetfile)
      @puppetfile = puppetfile
    end

    def call
      moduledir = @puppetfile.moduledir

      @puppetfile.load

      stale_mods = @puppetfile.stale_contents

      if stale_mods.empty?
        logger.debug "No stale modules in #{moduledir}"
      else
        logger.info "Purging stale modules from #{moduledir}"
        logger.debug "Stale modules in #{moduledir}: #{stale_mods.join(', ')}"
        @puppetfile.purge!
      end
    end
  end
end
end
end
