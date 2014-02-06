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
    @stdout = stdout
    @stderr = stderr
    @exit_code = exit_code
  end

  def [](field)
    send(field)
  end
end
