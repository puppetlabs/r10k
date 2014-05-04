require 'r10k/util/subprocess'

class R10K::SVN::Remote

  def initialize(baseurl)
    @baseurl = baseurl
  end

  def trunk
    "#{@baseurl}/trunk"
  end

  def branches
    text = svn ['ls', "#{@baseurl}/branches"]
    text.lines.map do |line|
      line.chomp!
      line.gsub!(%r[/$], '')
      line
    end
  end

  def branch_paths
    branches.map do |branch|
      Path.new(branch, @baseurl, "branches/#{branch}")
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

  class Path

    # @!attribute [r] name
    attr_reader :name

    # @!attribute [r] baseurl
    attr_reader :baseurl

    # @!attribute [r] path
    #   @return [String] The path to the location within the SVN repository
    #   @example
    #     Path.new('production', 'https://svn-server.site/repo', 'trunk')
    attr_reader :path

    def initialize(name, baseurl, path)
      @name    = name
      @baseurl = baseurl
      @path    = path
    end

    def url
      "#{@baseurl}/#{@path}"
    end
  end
end
