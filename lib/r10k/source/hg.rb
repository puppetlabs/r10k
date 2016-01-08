require 'r10k/hg'
require 'r10k/hg/cache'
require 'r10k/environment/hg'
require 'r10k/environment/name'

# This class implements a source for Git environments.
#
# A Mercurial source generates environments by locally caching the given Mercurial
# repository and enumerating the branches for the Mercurial repository. Branches
# are mapped to environments without modification.
class R10K::Source::Hg < R10K::Source::Base

  include R10K::Logging

  R10K::Source.register(:hg, self)

  # @!attribute [r] remote
  #   @return [String] The URL to the remote Mercurial repository
  attr_reader :remote

  # @!attribute [r] cache
  #   @api private
  #   @return [R10K::Hg::Cache] The Mercurial cache associated with this source
  attr_reader :cache

  # @!attribute [r] settings
  #   @return [Hash<Symbol, Object>] Additional settings that configure how
  #     the source should behave.
  attr_reader :settings

  # @!attribute [r] invalid_branches
  #   @return [String] How Mercurial branch names that cannot be cleanly mapped to
  #     Puppet environments will be handled.
  attr_reader :invalid_branches

  # Initialize the given source.
  #
  # @param name [String] The identifier for this source.
  # @param basedir [String] The base directory where the generated environments will be created.
  # @param options [Hash] An additional set of options for this source.
  #
  # @option options [Boolean, String] :prefix If a String this becomes the prefix.
  #   If true, will use the source name as the prefix.
  #   Defaults to false for no environment prefix.
  # @option options [String] :remote The URL to the base directory of the SVN repository
  # @option options [Hash] :remote Additional settings that configure how the
  #   source should behave.
  def initialize(name, basedir, options = {})
    super

    @environments = []

    @remote           = options[:remote]
    @invalid_branches = (options[:invalid_branches] || 'correct_and_warn')

    @cache  = R10K::Hg::Cache.generate(@remote)
  end

  # Update the git cache for this git source to get the latest list of environments.
  #
  # @return [void]
  def preload!
    logger.debug "Fetching '#{@remote}' to determine current branches."
    @cache.sync
  rescue => e
    raise R10K::Error.wrap(e, "Unable to determine current branches for Git source '#{@name}' (#{@basedir})")
  end
  alias fetch_remote preload!

  # Load the git remote and create environments for each branch. If the cache
  # has not been fetched, this will return an empty list.
  #
  # @return [Array<R10K::Environment::Hg>]
  def environments
    if not @cache.cached?
      []
    elsif @environments.empty?
      @environments = generate_environments()
    else
      @environments
    end
  end

  def generate_environments
    envs = []
    environment_names.each do |type, env|
      if env.valid?
        envs << R10K::Environment::Hg.new(env.name, @basedir, env.dirname,
                                           {:remote => remote, :rev => env.name, :ref_type => type})
      elsif env.correct?
        logger.warn "Environment #{env.name.inspect} contained non-word characters, correcting name to #{env.dirname}"
        envs << R10K::Environment::Hg.new(env.name, @basedir, env.dirname,
                                           {:remote => remote, :rev => env.name, :ref_type => type})
      elsif env.validate?
        logger.error "Environment #{env.name.inspect} contained non-word characters, ignoring it."
      end
    end

    envs
  end

  # List all environments that should exist in the basedir for this source
  # @note This is required by {R10K::Util::Basedir}
  # @return [Array<String>]
  def desired_contents
    environments.map {|env| env.dirname }
  end

  private

  def environment_names
    opts = {:prefix => @prefix, :invalid => @invalid_branches, :source => @name}
    branches = @cache.branches.map do |branch|
      [:branch, R10K::Environment::Name.new(branch, opts)]
    end

    bookmarks = @cache.bookmarks.map do |branch|
      [:bookmark, R10K::Environment::Name.new(branch, opts)]
    end

    branches + bookmarks
  end
end
