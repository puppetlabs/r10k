require 'r10k/git'
require 'r10k/environment'
require 'r10k/environment/name'

# This class implements a source for Git environments.
#
# A Git source generates environments by locally caching the given Git
# repository and enumerating the branches for the Git repository. Branches
# are mapped to environments without modification.
#
# @since 1.3.0
class R10K::Source::Git < R10K::Source::Base

  include R10K::Logging

  R10K::Source.register(:git, self)
  # Register git as the default source
  R10K::Source.register(nil, self)

  # @!attribute [r] remote
  #   @return [String] The URL to the remote git repository
  attr_reader :remote

  # @!attribute [r] cache
  #   @api private
  #   @return [R10K::Git::Cache] The git cache associated with this source
  attr_reader :cache

  # @!attribute [r] settings
  #   @return [Hash<Symbol, Object>] Additional settings that configure how
  #     the source should behave.
  attr_reader :settings

  # @!attribute [r] invalid_branches
  #   @return [String] How Git branch names that cannot be cleanly mapped to
  #     Puppet environments will be handled.
  attr_reader :invalid_branches

  # @!attribute [r] ignore_branch_prefixes
  #   @return [Array<String>] Array of strings used to remove repository branches
  #     that will be deployed as environments.
  attr_reader :ignore_branch_prefixes
  
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
    @ignore_branch_prefixes    = options[:ignore_branch_prefixes]

    @cache  = R10K::Git.cache.generate(@remote)
  end

  # Update the git cache for this git source to get the latest list of environments.
  #
  # @return [void]
  def preload!
    logger.debug _("Fetching '%{remote}' to determine current branches.") % {remote: @remote}
    @cache.sync
  rescue => e
    raise R10K::Error.wrap(e, _("Unable to determine current branches for Git source '%{name}' (%{basedir})") % {name: @name, basedir: @basedir})
  end
  alias fetch_remote preload!

  # Load the git remote and create environments for each branch. If the cache
  # has not been fetched, this will return an empty list.
  #
  # @return [Array<R10K::Environment::Git>]
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
    branch_names.each do |bn|
      if bn.valid?
        envs << R10K::Environment::Git.new(bn.name, @basedir, bn.dirname,
                                       {:remote => remote, :ref => bn.name})
      elsif bn.correct?
       logger.warn _("Environment %{env_name} contained non-word characters, correcting name to %{corrected_env_name}") % {env_name: bn.name.inspect, corrected_env_name: bn.dirname}
        envs << R10K::Environment::Git.new(bn.name, @basedir, bn.dirname,
                                       {:remote => remote, :ref => bn.name})
      elsif bn.validate?
       logger.error _("Environment %{env_name} contained non-word characters, ignoring it.") % {env_name: bn.name.inspect}
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

  def filter_branches(branches, ignore_prefixes)
    filter = Regexp.new("^(#{ignore_prefixes.join('|')}).?")
    branches = branches.select do |branch|
      result = filter.match(branch)
      if result
        logger.warn _("Branch %{branch} filtered out by ignore_branch_prefixes %{ibp}") % {branch: branch, ibp: @ignore_branch_prefixes}
      end
      !result
    end
    branches
  end

  def branch_names
    opts = {:prefix => @prefix, :invalid => @invalid_branches, :source => @name}
    branches = @cache.branches
    if @ignore_branch_prefixes && !@ignore_branch_prefixes.empty?
      branches = filter_branches(branches, @ignore_branch_prefixes)
    end
    branches.map do |branch|
      R10K::Environment::Name.new(branch, opts)
    end
  end
end
