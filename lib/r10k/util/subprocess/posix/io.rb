class R10K::Util::Subprocess::POSIX::IO < R10K::Util::Subprocess::IO

  def initialize
    @stdout = '/dev/null'
    @stderr = '/dev/null'
  end
end
