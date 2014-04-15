# @api private
class R10K::Util::Subprocess::Runner

  attr_accessor :cwd

  attr_reader :io

  attr_reader :pid

  attr_reader :status

  def initialize(argv)
    raise NotImplementedError
  end

  def start
    raise NotImplementedError
  end

  def wait
    raise NotImplementedError
  end

  def crashed?
    raise NotImplementedError
  end

  def exit_code
    raise NotImplementedError
  end
end
