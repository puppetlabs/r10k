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
        task_runner.add_task_after(self, task)
      end
    end
  end
end
end
end
