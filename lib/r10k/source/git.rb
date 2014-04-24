require 'r10k/git'
require 'r10k/environment'
require 'r10k/util/purgeable'

class R10K::Source::Git < R10K::Source::Base

  # @!attribute [r] remote
  #   @return [String] The URL to the remote git repository
  attr_reader :remote

  # @!attribute [r] cache
  #   @api private
  #   @return [R10K::Git::Cache] The git cache associated with this source
  attr_reader :cache

  def initialize(basedir, name, options = {})
    super

    @remote = options[:remote]
    @cache  = R10K::Git::Cache.generate(@remote)
  end

  # Fetch the git remote and and create environments for each branch.
  #
  # @return [void]
  def fetch
    @cache.sync
    self.load
  end

  # Load the git remote and create environments for each branch. This requires
  # the cache to be fetched beforehand.
  #
  # @return [void]
  def load
    return unless @cache.cached?

    @environments = @cache.branches.map do |branch|
      dirname = dirname_for_branch(branch)
      R10K::Environment::Git.new(@basedir, dirname, {:remote => remote, :ref => branch})
    end
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

  # @todo branch sanitization?
  def dirname_for_branch(branch)
    if @prefix
      branch_dirname = "#{@name}_#{branch}"
    else
      branch_dirname = branch
    end

    branch_dirname
  end
end
