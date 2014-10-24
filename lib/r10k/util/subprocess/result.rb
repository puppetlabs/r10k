# @api private
class R10K::Util::Subprocess::Result

  # @!attribute [r] argv
  #   @return [Array<String>]
  attr_reader :argv

  # @!attribute [r] cmd
  #   @return [String]
  attr_reader :cmd

  # @!attribute [r] stdout
  #   @return [String]
  attr_reader :stdout

  # @!attribute [r] stderr
  #   @return [String]
  attr_reader :stderr

  # @!attribute [r] exit_code
  #   @return [Integer]
  attr_reader :exit_code

  def initialize(argv, stdout, stderr, exit_code)
    @argv = argv
    @cmd = argv.join(' ')
    @stdout = stdout.chomp
    @stderr = stderr.chomp
    @exit_code = exit_code
  end

  def format(with_cmd = true)
    msg = []
    if with_cmd
      msg << "Command: #{@cmd}"
    end
    if !@stdout.empty?
      msg << "Stdout:"
      msg << @stdout
    end
    if !@stderr.empty?
      msg << "Stderr:"
      msg << @stderr
    end
    msg << "Exit code: #{@exit_code}"
    msg.join("\n")
  end

  def failed?
    exit_code != 0
  end

  def success?
    exit_code == 0
  end
end
