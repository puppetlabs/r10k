require 'r10k/hg'
require 'r10k/logging'
require 'r10k/util/subprocess'

class R10K::Hg::Repository
  # @attribute [r] path
  #   @return [Pathname] The path to the Mercurial directory
  attr_reader :path

  # @param basedir [String] The base directory of the Mercurial repository
  # @param dirname [String] The directory name of the Mercurial repository
  def initialize(basedir, dirname, options = {})
    @path = Pathname.new(File.join(basedir, dirname))
    @options = options
  end


  def clone(remote, opts = {})
    dest = path.to_s
    FileUtils.mkdir_p dest unless File.exist?(dest)

    args = ['clone']

    options = @options[:clone] || {}

    args << '--branch' << options[:branch] if options[:branch]
    args << '--rev' << options[:rev] if options[:rev]

    if opts[:rev]
      args << '--updaterev' << opts[:rev]
    elsif options[:noupdate]
      args << '--noupdate'
    end

    args << remote << dest

    hg args
  end

  def fetch
    args = ['pull']

    options = @options[:pull] || {}
    args << '--branch' << options[:branch] if options[:branch]
    args << '--rev' << options[:rev] if options[:rev]

    hg args, :path => path.to_s

    result = hg ['outgoing', '--bookmarks'], :path => path.to_s, :raise_on_fail => false
    if result.success?
      result.stdout.lines do |line|
        if m = line.match(/^\s+([^\s]+)\s+[a-fA-F0-9]+$/)
          hg ['bookmark', '-d', m[1]], :path => path.to_s
        end
      end
    end
  end

  # Check out the given Mercurial revision
  #
  # @param ref [String] The Mercurial reference to check out
  def checkout(rev)
    hg ['checkout', rev], :path => path.to_s
  end

  def exist?
    @path.exist?
  end

  def add_path(path_name, remote)
    hgrc = File.join(path.to_s, '.hg/hgrc')

    hgrc_lines = File.readlines(hgrc)

    index = hgrc_lines.index { |line| line =~ /\s*\[paths\]\s*\n/ } || -1

    if index == -1
      hgrc_lines.insert( index, "[paths]\n")
    else
      index = index + 1
    end

    hgrc_lines.insert( index, "#{path_name} = #{remote}\n")

    File.write(hgrc, hgrc_lines.join(''))
  end

  # Resolve the given Mercurial revision to a commit
  #
  # @param pattern [String] The Mercurial revision to resolve
  # @return [String, nil] The commit SHA if the revision could be resolved, nil otherwise.
  def resolve(pattern)
    result = hg ['log', '--rev', pattern, '--template', "{node}"], :path => path.to_s, :raise_on_fail => false
    if result.success?
      result.stdout
    end
  end

  # @return [String] The currently checked out ref
  def head
    resolve('.')
  end

  # @return [Array<String>] All branches in this repository
  def branches
    output = hg ['branches', '--template', '{branch}\n'], :path => path.to_s
    output.stdout.split("\n")
  end

  # @return [Array<String>] All bookmarks in this repository
  def bookmarks
    output = hg ['bookmarks', '--template', '{bookmark}\n'], :path => path.to_s
    output.stdout.split("\n")
  end

  # @return [Array<String>] All tags in this repository
  def tags
    output = hg ['tags', '--template', '{tag}\n'], :path => path.to_s
    output.stdout.split("\n")
  end

  # @return [Symbol] The type of the given ref, one of :branch, :tag, :changeset, or :unknown
  def ref_type(pattern)
    if branches.include? pattern
      :branch
    elsif bookmarks.include? pattern
      :bookmark
    elsif tags.include? pattern
      :tag
    elsif resolve(pattern)
      :changeset
    else
      :unknown
    end
  end

  # @return [String] The origin remote URL
  def resolve_path(path_name)
    result = hg(['showconfig', "paths.#{path_name}"], :path => path.to_s, :raise_on_fail => false)
    if result.success?
      result.stdout
    end
  end

  include R10K::Logging

  private

  # Wrap hg commands
  #
  # @param cmd [Array<String>] cmd The arguments for the Mercurial prompt
  # @param opts [Hash] opts
  #
  # @option opts [String] :path
  # @option opts [String] :raise_on_fail
  #
  # @raise [R10K::ExecutionFailure] If the executed command exited with a
  #   nonzero exit code.
  #
  # @return [String] The Mercurial command output
  def hg(cmd, opts = {})
    raise_on_fail = opts.fetch(:raise_on_fail, true)

    argv = %w{hg}

    if opts[:path]
      argv << "--repository"   << File.join(opts[:path])
    end

    argv.concat(cmd)

    subproc = R10K::Util::Subprocess.new(argv)
    subproc.raise_on_fail = raise_on_fail
    subproc.logger = self.logger

    result = subproc.execute

    result
  end
end
