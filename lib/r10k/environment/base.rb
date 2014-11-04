# This class defines a common interface for environment implementations.
#
# @since 1.3.0
class R10K::Environment::Base

  # @!attribute [r] name
  #   @return [String] A name for this environment that is unique to the given source
  attr_reader :name

  # @!attribute [r] basedir
  #   @return [String] The path that this environment will be created in
  attr_reader :basedir

  # @!attribute [r] dirname
  #   @return [String] The directory name for the given environment
  attr_reader :dirname

  # @!attribute [r] path
  #   @return [Pathname] The full path to the given environment
  attr_reader :path

  # @!attribute [r] puppetfile
  #   @api public
  #   @return [R10K::Puppetfile] The puppetfile instance associated with this environment
  attr_reader :puppetfile

  # Initialize the given environment.
  #
  # @param name [String] The unique name describing this environment.
  # @param basedir [String] The base directory where this environment will be created.
  # @param dirname [String] The directory name for this environment.
  # @param options [Hash] An additional set of options for this environment.
  #   The semantics of this environment may depend on the environment implementation.
  def initialize(name, basedir, dirname, options = {})
    @name    = name
    @basedir = basedir
    @dirname = dirname
    @options = options

    @full_path = File.join(@basedir, @dirname)
    @path = Pathname.new(File.join(@basedir, @dirname))
    @puppetfile  = R10K::Puppetfile.new(@full_path)
  end

  # Synchronize the given environment.
  #
  # @api public
  # @abstract
  # @return [void]
  def sync
    raise NotImplementedError, "#{self.class} has not implemented method #{__method__}"
  end

  # @return [Array<R10K::Module::Base>] All modules defined in the Puppetfile
  #   associated with this environment.
  def modules
    @puppetfile.load
    @puppetfile.modules
  end
end
