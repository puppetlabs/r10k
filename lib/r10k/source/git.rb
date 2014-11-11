require 'r10k/git'
require 'r10k/environment'
require 'r10k/util/purgeable'
require 'r10k/util/core_ext/hash_ext'

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

  # Initialize the given source.
  #
  # @param name [String] The identifier for this source.
  # @param basedir [String] The base directory where the generated environments will be created.
  # @param options [Hash] An additional set of options for this source.
  #
  # @option options [Boolean] :prefix Whether to prefix the source name to the
  #   environment directory names. Defaults to false.
  # @option options [String] :remote The URL to the base directory of the SVN repository
  # @option options [Hash] :remote Additional settings that configure how the
  #   source should behave.
  def initialize(name, basedir, options = {})
    super

    @environments = []

    @remote           = options[:remote]
    @invalid_branches = (options[:invalid_branches] || 'correct_and_warn')

    @cache  = R10K::Git::Cache.generate(@remote)
  end

  # Update the git cache for this git source to get the latest list of environments.
  #
  # @return [void]
  def preload!
    logger.debug "Determining current branches for Git source #{@remote.inspect}"
    @cache.sync
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
       logger.warn "Environment #{bn.name.inspect} contained non-word characters, correcting name to #{bn.dirname}"
        envs << R10K::Environment::Git.new(bn.name, @basedir, bn.dirname,
                                       {:remote => remote, :ref => bn.name})
      elsif bn.validate?
       logger.error "Environment #{bn.name.inspect} contained non-word characters, ignoring it."
      end
    end

    envs
  end

  include R10K::Util::Purgeable

  def managed_directory
    @basedir
  end

  def current_contents
    dir = self.managed_directory
    glob_part = @prefix ? @name.to_s() + '_*' : '*'
    glob_exp = File.join(dir, glob_part)

    Dir.glob(glob_exp).map do |fname|
      File.basename fname
    end
  end

  # List all environments that should exist in the basedir for this source
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    environments.map {|env| env.dirname }
  end

  private

  def branch_names
    @cache.branches.map do |branch|
      BranchName.new(branch, {
        :prefix     => @prefix,
        :sourcename => @name,
        :invalid    => @invalid_branches,
      })
    end
  end

  # @api private
  class BranchName

    attr_reader :name

    INVALID_CHARACTERS = %r[\W]

    def initialize(name, opts)
      @name = name
      @opts = opts

      @prefix = opts[:prefix]
      @sourcename = opts[:sourcename]
      @invalid = opts[:invalid]

      case @invalid
      when 'correct_and_warn'
        @validate = true
        @correct  = true
      when 'correct'
        @validate = false
        @correct  = true
      when 'error'
        @validate = true
        @correct  = false
      when NilClass
        @validate = opts[:validate]
        @correct = opts[:correct]
      end
    end

    def correct?; @correct end
    def validate?; @validate end

    def valid?
      if @validate
        ! @name.match(INVALID_CHARACTERS)
      else
        true
      end
    end

    def dirname
      dir = @name.dup

      if @prefix
        dir = "#{@sourcename}_#{dir}"
      end

      if @correct
        dir.gsub!(INVALID_CHARACTERS, '_')
      end

      dir
    end

  end
end
