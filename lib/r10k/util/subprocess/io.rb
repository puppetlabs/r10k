class R10K::Util::Subprocess::IO

  attr_reader :stdin

  attr_accessor :stdout
  attr_accessor :stderr

  def initialize
    @stdout = '/dev/null'
    @stderr = '/dev/null'
  end
end
