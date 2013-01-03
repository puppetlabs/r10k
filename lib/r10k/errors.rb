require 'r10k'

module R10K
  class ExecutionFailure < Exception
    attr_accessor :exit_code, :stdout, :stderr
  end
end
