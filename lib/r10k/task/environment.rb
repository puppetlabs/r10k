require 'r10k/task'
require 'r10k/task/puppetfile'

module R10K
module Task
module Environment
  class Deploy < R10K::Task::Base

    attr_writer :update_puppetfile

    def initialize(environment)
      @environment = environment

      @update_puppetfile = false
    end

    def call
      logger.notice "Deploying environment #{@environment.dirname}"
      @environment.sync

      if @update_puppetfile
        task = R10K::Task::Puppetfile::Sync.new(@environment.puppetfile)
        task_runner.insert_task_after(self, task)
      end
    end
  end
end
end
end
