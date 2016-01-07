require 'r10k/logging'
require 'r10k/puppetfile'
require 'r10k/hg/stateful_repository'
require 'forwardable'

# This class implements an environment based on a Mercurial branch.
class R10K::Environment::Hg < R10K::Environment::Base

  include R10K::Logging

  # @!attribute [r] remote
  #   @return [String] The URL to the remote Mercurial repository
  attr_reader :remote

  # @!attribute [r] ref
  #   @return [String] The Mercurial revision to use for this environment
  attr_reader :rev

  # @!attribute [r] repo
  #   @api private
  #   @return [R10K::Hg::StatefulRepository] The Mercurial repo backing this environment
  attr_reader :repo

  # Initialize the given SVN environment.
  #
  # @param name [String] The unique name describing this environment.
  # @param basedir [String] The base directory where this environment will be created.
  # @param dirname [String] The directory name for this environment.
  # @param options [Hash] An additional set of options for this environment.
  #
  # @param options [String] :remote The URL to the remote Mercurial repository
  # @param options [String] :rev The Mercurial revision to use for this environment
  def initialize(name, basedir, dirname, options = {})
    super
    @remote = options[:remote]
    @rev    = options[:rev]

    @repo = R10K::Hg::StatefulRepository.new(@rev, @remote, @basedir, @dirname)
  end

  # Clone or update the given Mercurial environment.
  #
  # If the environment is being created for the first time, it will
  # automatically update all modules to ensure that the environment is complete.
  #
  # @api public
  # @return [void]
  def sync
    @repo.sync
    @synced = true
  end

  # Return a sting which uniquely identifies (per source) the current state of the
  # environment.
  #
  # @api public
  # @return [String]
  def signature
    @repo.head
  end

  extend Forwardable

  def_delegators :@repo, :status
end
