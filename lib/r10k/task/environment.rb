require 'r10k/task'
require 'r10k/task/puppetfile'

module R10K
module Task
module Environment
  class Deploy < R10K::Task::Base
    def initialize(environment, opts = {})
      @environment = environment

      @puppetfile = opts.delete(:puppetfile)

      raise "Unrecognized options: #{opts.keys.join(', ')}" unless opts.empty?
    end

    def call
      logger.notice "Deploying environment #{@environment.dirname}"
      @environment.sync

      if @puppetfile
        task = R10K::Task::Puppetfile::Sync.new(@environment.puppetfile)
        task_runner.add_task_after(self, task)
      end
    end
  end
end
end
end
