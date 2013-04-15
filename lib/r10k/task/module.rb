require 'r10k/task'

module R10K
module Task
module Module
  class Sync < R10K::Task::Base
    def initialize(mod)
      @mod = mod
    end

    def call
      logger.info "Deploying #{@mod.name} into #{@mod.basedir}"
      @mod.sync
    end
  end
end
end
end
