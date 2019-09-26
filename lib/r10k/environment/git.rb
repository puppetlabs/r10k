require 'r10k/logging'
require 'r10k/puppetfile'
require 'r10k/git/stateful_repository'
require 'forwardable'

# This class implements an environment based on a Git branch.
#
# @since 1.3.0
class R10K::Environment::Git < R10K::Environment::Base

  include R10K::Logging

  R10K::Environment.register(:git, self)
  # Register git as the default environment type
  R10K::Environment.register(nil, self)

  # @!attribute [r] remote
  #   @return [String] The URL to the remote git repository
  attr_reader :remote

  # @!attribute [r] ref
  #   @return [String] The git reference to use for this environment
  attr_reader :ref

  # @!attribute [r] repo
  #   @api private
  #   @return [R10K::Git::StatefulRepository] The git repo backing this environment
  attr_reader :repo

  # Initialize the given Git environment.
  #
  # @param name [String] The unique name describing this environment.
  # @param basedir [String] The base directory where this environment will be created.
  # @param dirname [String] The directory name for this environment.
  # @param options [Hash] An additional set of options for this environment.
  #
  # @param options [String] :remote The URL to the remote git repository
  # @param options [String] :ref The git reference to use for this environment
  def initialize(name, basedir, dirname, options = {})
    super
    @remote = options[:remote]
    @ref    = options[:ref]

    @repo = R10K::Git::StatefulRepository.new(@remote, @basedir, @dirname)
  end

  # Clone or update the given Git environment.
  #
  # If the environment is being created for the first time, it will
  # automatically update all modules to ensure that the environment is complete.
  #
  # @api public
  # @return [void]
  def sync
    @repo.sync(@ref)
  end

  def status
    @repo.status(@ref)
  end

  # Return a sting which uniquely identifies (per source) the current state of the
  # environment.
  #
  # @api public
  # @return [String]
  def signature
    @repo.head
  end

  include R10K::Util::Purgeable

  def managed_directories
    [@full_path]
  end

  # Returns an array of the full paths to all the content being managed.
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    desired = [File.join(@full_path, '.git')]
    desired += @repo.tracked_paths.map { |entry| File.join(@full_path, entry) }
  end
end
