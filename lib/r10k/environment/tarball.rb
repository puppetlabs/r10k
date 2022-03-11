require 'r10k/util/setopts'
require 'r10k/tarball'
require 'r10k/environment'

class R10K::Environment::Tarball < R10K::Environment::WithModules

  R10K::Environment.register(:tarball, self)

  # @!attribute [r] tarball
  #   @api private
  #   @return [R10K::Tarball]
  attr_reader :tarball

  include R10K::Util::Setopts

  # Initialize the given tarball environment.
  #
  # @param name [String] The unique name describing this environment.
  # @param basedir [String] The base directory where this environment will be created.
  # @param dirname [String] The directory name for this environment.
  # @param options [Hash] An additional set of options for this environment.
  #
  # @param options [String] :source Where to get the tarball from
  # @param options [String] :version The sha256 digest of the tarball
  def initialize(name, basedir, dirname, options = {})
    super
    setopts(options, {
      # Standard option interface
      :type      => ::R10K::Util::Setopts::Ignore,
      :source    => :self,
      :version   => :checksum,

      # Type-specific options
      :checksum => :self,
    })

    @tarball = R10K::Tarball.new(name, @source, checksum: @checksum, remove_wrapper_dir: true)
  end

  def path
    @path ||= Pathname.new(File.join(@basedir, @dirname))
  end

  def sync
    tarball.get unless tarball.cache_valid?
    case status
    when :absent, :mismatched
      tarball.unpack(path.to_s)
      # Untracked files left behind from previous extractions are expected to
      # be deleted by r10k's purge facility.
    end
  end

  def status
    if not path.exist?
      :absent
    elsif not (tarball.cache_valid? && tarball.insync?(path.to_s, ignore_untracked_files: true))
      :mismatched
    else
      :insync
    end
  end

  def signature
    @checksum || @tarball.cache_checksum
  end

  include R10K::Util::Purgeable

  # Returns an array of the full paths to all the content being managed.
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    desired = []
    desired += @tarball.paths.map { |entry| File.join(@full_path, entry) }
    desired += super
  end
end
