require 'r10k/task'
require 'r10k/task/puppetfile'

module R10K
module Task
module Environment
  class Deploy < R10K::Task::Base

    attr_writer :update_puppetfile
    attr_writer :update_puppetfile_if_changed

    def initialize(environment)
      @environment = environment

      @update_puppetfile = false
      @update_puppetfile_if_changed = false
    end

    def call
      logger.notice "Deploying environment #{@environment.dirname}"

      environment_outdated = @environment.outdated?

      @environment.sync

      if update_puppetfile?(environment_outdated)
        task = R10K::Task::Puppetfile::Sync.new(@environment.puppetfile)
        task_runner.insert_task_after(self, task)
      end
    end

    private
      def update_puppetfile?(environment_outdated)
        @update_puppetfile || (@update_puppetfile_if_changed && environment_outdated)
      end
  end
end
end
end
