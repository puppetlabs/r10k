require 'r10k/logging'

module R10K
module Task
  class Base
    include R10K::Logging

    # @!attribute [r] task_runner
    #   @return [R10K::TaskRunner] The task runner that's executing this command
    attr_accessor :task_runner
  end
end
end
