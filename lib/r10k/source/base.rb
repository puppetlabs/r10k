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

  # @!attribute [r] environments
  #   @return [Array<R10K::Environment::Base>] An array of environments
  #     created from this source.
  attr_reader :environments

  def initialize(basedir, name, options = {})
    @basedir = basedir
    @name    = name
    @prefix  = options.delete(:prefix)
    @options = options

    @environments = []
  end

  # Perform any actions needed for loading environments that may have side
  # effects.
  #
  # Actions done during preloading may include things like updating caches or
  # performing network queries. If an environment has not been preloaded but
  # {#environments} is invoked, it should return the best known state of
  # environments or return an empty list.
  #
  # @abstract
  def preload!

  end
end
