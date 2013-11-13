require 'r10k/git/cache'
require 'r10k/deployment/environment'
require 'r10k/deployment/basedir'
require 'r10k/util/purgeable'

module R10K
class Deployment
class Source
  # Represents a git repository to map branches to environments
  #
  # This module is backed with a bare git cache that's used to enumerate
  # branches. The cache isn't used for anything else here, but all environments
  # using that remote will be able to reuse the cache.

  # @!attribute [r] name
  #   @return [String] The short name for the deployment source
  attr_reader :name

  # @!attribute [r] source
  #   @return [String] The git remote to use for environments
  attr_reader :remote

  # @!attribute [r] basedir
  #   @return [String] The base directory to deploy the environments into
  attr_reader :basedir

  # @!attribute [r] environments
  #   @return [Array<R10K::Deployment::Environment>] All environments for this source
  attr_reader :environments

  # Create a new source from a hash representation
  #
  # @param name [String] The name of the source
  # @param opts [Hash] The properties to use for the source
  # @param prefix [true, false] Whether to prefix the source name to created
  #   environments
  #
  # @options opts [String] :remote The git remote for the given source
  # @options opts [String] :basedir The directory to create environments in
  # @options opts [true, false] :prefix Whether the environment names should
  #   be prefixed by the source name. Defaults to false. This takes precedence
  #   over the `prefix` argument
  #
  # @return [R10K::Deployment::Source]
  def self.vivify(name, attrs, prefix = false)
    remote  = (attrs.delete(:remote) || attrs.delete('remote'))
    basedir = (attrs.delete(:basedir) || attrs.delete('basedir'))
    prefix_config = (attrs.delete(:prefix) || attrs.delete('prefix'))
    prefix_outcome = prefix_config.nil? ? prefix : prefix_config

    raise ArgumentError, "Unrecognized attributes for #{self.name}: #{attrs.inspect}" unless attrs.empty?
    new(name, remote, basedir, prefix_outcome)
  end

  def initialize(name, remote, basedir, prefix = nil)
    @name    = name
    @remote  = remote
    @basedir = basedir
    @prefix = prefix.nil? ? false : prefix

    @cache   = R10K::Git::Cache.generate(@remote)

    load_environments
  end

  def fetch_remote
    @cache.sync
    load_environments
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

  def load_environments
    if @cache.cached?
      @environments = @cache.branches.map do |branch|
        if @prefix
          R10K::Deployment::Environment.new(branch, @remote, @basedir, nil, @name.to_s())
        else
          R10K::Deployment::Environment.new(branch, @remote, @basedir)
        end
      end
    else
      @environments = []
    end
  end
end
end
end
