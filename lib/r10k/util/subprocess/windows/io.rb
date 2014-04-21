class R10K::Util::Subprocess::Windows::IO < R10K::Util::Subprocess::IO
  def initialize
    @stdout = 'NUL:'
    @stderr = 'NUL:'
  end
end
