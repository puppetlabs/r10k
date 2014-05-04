require 'r10k/git'
require 'r10k/environment'
require 'r10k/util/purgeable'
require 'r10k/util/core_ext/hash_ext'

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

  def initialize(basedir, name, options = {})
    super

    @environments = []

    @remote   = options[:remote]
    @settings = options[:settings] || {}
    @settings.extend R10K::Util::CoreExt::HashExt::SymbolizeKeys
    @settings.symbolize_keys!

    @cache  = R10K::Git::Cache.generate(@remote)
  end

  # Update the git cache for this git source to get the latest list of environments.
  #
  # @return [void]
  def preload!
    logger.info "Determining current branches for #{@remote.inspect}"
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
    elsif not @environments.empty?
      @environments
    else
      @environments = generate_environments()
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
    @environments.map {|env| env.dirname }
  end

  private

  def branch_names
    @cache.branches.map do |branch|
      BranchName.new(branch, {
        :prefix     => @prefix,
        :sourcename => @name,
        :invalid    => @settings.fetch(:invalid, 'correct_and_warn')
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
