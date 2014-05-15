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
  end

  # Synchronize the given environment.
  #
  # @api public
  # @abstract
  # @return [void]
  def sync
    raise NotImplementedError, "#{self.class} has not implemented method #{__method__}"
  end
end
