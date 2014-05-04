require 'r10k/util/subprocess'

class R10K::SVN::Remote

  def initialize(baseurl)
    @baseurl = baseurl
  end

  # @todo validate that the path to trunk exists in the remote
  def trunk
    "#{@baseurl}/trunk"
  end

  # @todo gracefully handle cases where no branches exist
  def branches
    text = svn ['ls', "#{@baseurl}/branches"]
    text.lines.map do |line|
      line.chomp!
      line.gsub!(%r[/$], '')
      line
    end
  end

  private

  include R10K::Logging

  # Wrap SVN commands
  #
  # @param argv [Array<String>]
  # @param opts [Hash]
  #
  # @option opts [Pathname] :cwd The directory to run the command in
  #
  # @return [String] The stdout from the given command
  def svn(argv, opts = {})
    argv.unshift('svn')

    subproc = R10K::Util::Subprocess.new(argv)
    subproc.raise_on_fail = true
    subproc.logger = self.logger

    subproc.cwd = opts[:cwd]
    result = subproc.execute

    result.stdout
  end
end
