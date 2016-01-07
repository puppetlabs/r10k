require 'r10k/hg/base_repository'

# Create and manage Mercurial bare repositories.
class R10K::Hg::BareRepository < R10K::Hg::BaseRepository

  # @param basedir [String] The base directory of the Mercurial repository
  # @param dirname [String] The directory name of the Mercurial repository
  def initialize(basedir, dirname)
    @path = Pathname.new(File.join(basedir, dirname))
  end

  # @return [Pathname] The path to this Mercurial repository
  def hg_dir
    @path
  end

  def clone(remote)
    dest = hg_dir.to_s
    FileUtils.mkdir_p dest unless File.exist?(dest)
    hg ['clone', '--noupdate', remote, dest]
  end

  def fetch
    hg ['pull'], :path => hg_dir.to_s
  end

  def exist?
    @path.exist?
  end
end
