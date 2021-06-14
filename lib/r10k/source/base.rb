require 'r10k/logging'

# This class defines a common interface for source implementations.
#
# @since 1.3.0
class R10K::Source::Base

  include R10K::Logging

  # @!attribute [r] basedir
  #   @return [String] The path this source will place environments in
  attr_reader :basedir

  # @!attribute [r] name
  #   @return [String] The short name for this environment source
  attr_reader :name

  # @!attribute [r] prefix
  #   @return [String, nil] The prefix for the environments basedir.
  #     Defaults to nil.
  attr_reader :prefix

  # @!attribute [r] puppetfile_name
  #   @return [String, nil] The Name of the puppetfile
  #     Defaults to nil.
  attr_reader :puppetfile_name

  # Initialize the given source.
  #
  # @param name [String] The identifier for this source.
  # @param basedir [String] The base directory where the generated environments will be created.
  # @param options [Hash] An additional set of options for this source. The
  #   semantics of this hash may depend on the source implementation.
  #
  # @option options [Boolean, String] :prefix If a String this becomes the prefix.
  #   If true, will use the source name as the prefix. All sources should respect this option.
  #   Defaults to false for no environment prefix.
  # @option options [String] :strip_component If a string, this value will be
  #   removed from the beginning of each generated environment's name, if
  #   present. If the string is contained within two "/" characters, it will
  #   be treated as a regular expression.
  def initialize(name, basedir, options = {})
    @name    = name
    @basedir = Pathname.new(basedir).cleanpath.to_s
    @prefix  = options.delete(:prefix)
    @strip_component = options.delete(:strip_component)
    @puppetfile_name = options.delete(:puppetfile_name)
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

  # Perform actions to reload environments after the `preload!`. Similar
  # to preload!, and likely to include network queries and rerunning
  # environment generation.
  #
  # @api public
  # @abstract
  # @return [void]
  def reload!
  end

  # Enumerate the environments associated with this SVN source.
  #
  # @api public
  # @abstract
  # @return [Array<R10K::Environment::Base>] An array of environments created
  #   from this source.
  def environments
    raise NotImplementedError, _("%{class} has not implemented method %{method}") % {class: self.class, method: __method__}
  end

  def accept(visitor)
    visitor.visit(:source, self) do
      environments.each do |env|
        env.accept(visitor)
      end
    end
  end
end
