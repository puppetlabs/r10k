require 'r10k/hg/base_repository'

# Manage a non-bare Mercurial repository
class R10K::Hg::WorkingRepository < R10K::Hg::BaseRepository

  # @attribute [r] path
  #   @return [Pathname]
  attr_reader :path

  # @return [Pathname] The path to the Mercurial directory inside of this repository
  def hg_dir
    @path
  end

  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))
  end

  # Clone this Mercurial repository
  #
  # @param remote [String] The Mercurial remote to clone
  # @param opts [Hash]
  #
  # @options opts [String] :ref The Mercurial revision to check out on clone
  #
  # @return [void]
  def clone(remote, opts = {})
    dest = @path.to_s
    FileUtils.mkdir_p dest unless File.exist?(dest)
    hg ['clone', remote, dest]

    if opts[:rev]
      checkout(opts[:rev])
    end
  end

  # Check out the given Mercurial revision
  #
  # @param ref [String] The Mercurial reference to check out
  def checkout(rev)
    hg ['checkout', rev], :path => hg_dir.to_s
  end

  def fetch
    hg ['pull'], :path => hg_dir.to_s
  end

  def exist?
    @path.exist?
  end

  # @return [String] The currently checked out ref
  def head
    resolve('HEAD')
  end

  # @return [String] The origin remote URL
  def resolve_path(path_name)
    result = hg(['showconfig', "paths.#{path_name}"], :path => hg_dir.to_s, :raise_on_fail => false)
    if result.success?
      result.stdout
    end
  end
end
