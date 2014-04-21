require 'open3'

class R10K::Util::Subprocess::Windows::Runner < R10K::Util::Subprocess::Runner

  def initialize(argv)
    @argv = argv
    @io = R10K::Util::Subprocess::Windows::IO.new
  end

  def run
    cmd = @argv.join(' ')

    stdout, stderr, status = Open3.capture3(cmd)

    @status = status
    @result = R10K::Util::Subprocess::Result.new(@argv, stdout, stderr, status.exitstatus)
  end

  def exit_code
    @status.exitstatus
  end

  def crashed?
    exit_code != 0
  end
end
