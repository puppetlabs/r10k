require 'r10k/puppetfile'
require 'r10k/svn/working_dir'
require 'r10k/util/setopts'

# This class implements an environment based on an SVN branch.
#
# @since 1.3.0
class R10K::Environment::SVN < R10K::Environment::Base

  include R10K::Logging

  # @!attribute [r] remote
  #   @return [String] The URL to the remote SVN branch to check out
  attr_reader :remote

  # @!attribute [r] working_dir
  #   @api private
  #   @return [R10K::SVN::WorkingDir] The SVN working directory backing this environment
  attr_reader :working_dir

  # @!attribute [r] username
  #   @return [String, nil] The SVN username to be passed to the underlying SVN commands
  #   @api private
  attr_reader :username

  # @!attribute [r] password
  #   @return [String, nil] The SVN password to be passed to the underlying SVN commands
  #   @api private
  attr_reader :password

  include R10K::Util::Setopts

  # Initialize the given SVN environment.
  #
  # @param name [String] The unique name describing this environment.
  # @param basedir [String] The base directory where this environment will be created.
  # @param dirname [String] The directory name for this environment.
  # @param options [Hash] An additional set of options for this environment.
  #
  # @option options [String] :remote The URL to the remote SVN branch to check out
  # @option options [String] :username The SVN username
  # @option options [String] :password The SVN password
  def initialize(name, basedir, dirname, options = {})
    super

    setopts(options, {:remote => :self, :username => :self, :password => :self})

    @working_dir = R10K::SVN::WorkingDir.new(Pathname.new(@full_path), :username => @username, :password => @password)
  end

  # Perform an initial checkout of the SVN repository or update the repository.
  #
  # If the environment is being created for the first time, it will
  # automatically update all modules to ensure that the environment is complete.
  #
  # @api public
  # @return [void]
  def sync
    if @working_dir.is_svn?
      @working_dir.update
    else
      @working_dir.checkout(@remote)
    end
    @synced = true
  end

  def status
    if !@path.exist?
      :absent
    elsif !@working_dir.is_svn?
      :mismatched
    elsif !(@remote == @working_dir.url)
      :mismatched
    elsif !@synced
      :outdated
    else
      :insync
    end
  end
end
