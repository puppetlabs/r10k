# This class defines a common interface for source implementations.
#
# @since 1.3.0
class R10K::Source::Base

  # @!attribute [r] basedir
  #   @return [String] The path this source will place environments in
  attr_reader :basedir

  # @!attribute [r] name
  #   @return [String] The short name for this environment source
  attr_reader :name

  # @!attribute [r] prefix
  #   @return [true, false] Whether the source name should be prefixed to each
  #     environment basedir. Defaults to false
  attr_reader :prefix

  # Initialize the given source.
  #
  # @param basedir [String] The base directory where the generated environments will be created.
  # @param name [String] The identifier for this source.
  # @param options [Hash] An additional set of options for this source. The
  #   semantics of this hash may depend on the source implementation.
  #
  # @option options [Boolean] :prefix Whether to prefix the source name to the
  #   environment directory names. All sources should respect this option.
  #   Defaults to false.
  def initialize(basedir, name, options = {})
    @basedir = basedir
    @name    = name
    @prefix  = options.delete(:prefix)
    @options = options
  end

  # Perform any actions needed for loading environments that may have side
  # effects.
  #
  # Actions done during preloading may include things like updating caches or
  # performing network queries. If an environment has not been preloaded but
  # {#environments} is invoked, it should return the best known state of
  # environments or return an empty list.
  #
  # @api public
  # @abstract
  # @return [void]
  def preload!

  end

  # Enumerate the environments associated with this SVN source.
  #
  # @api public
  # @abstract
  # @return [Array<R10K::Environment::Base>] An array of environments created
  #   from this source.
  def environments
    raise NotImplementedError, "#{self.class} has not implemented method #{__method__}"
  end
end
