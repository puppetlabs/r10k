module R10K
class ExecutionFailure < StandardError
  attr_accessor :exit_code, :stdout, :stderr
end
end
