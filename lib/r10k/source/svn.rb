require 'r10k/svn'
require 'r10k/environment'
require 'r10k/util/setopts'

# This class implements a source for SVN environments.
#
# An SVN source generates environments by enumerating the branches and trunk
# for a given SVN remote. SVN repositories must conform to the conventional
# SVN repository structure with the directories trunk/, branches/, and
# optionally tags/ in the root of the repository. The trunk/ directory is
# specifically mapped to the production environment, branches are created
# as environments with the name of the given branch.
#
# @see http://svnbook.red-bean.com/en/1.7/svn.branchmerge.maint.html
# @since 1.3.0
class R10K::Source::SVN < R10K::Source::Base

  R10K::Source.register(:svn, self)

  # @!attribute [r] remote
  #   @return [String] The URL to the base directory of the SVN repository
  attr_reader :remote

  # @!attribute [r] svn_remote
  #   @api private
  #   @return [R10K::SVN::Remote]
  attr_reader :svn_remote

  # @!attribute [r] username
  #   @return [String, nil] The SVN username to be passed to the underlying SVN commands
  #   @api private
  attr_reader :username

  # @!attribute [r] password
  #   @return [String, nil] The SVN password to be passed to the underlying SVN commands
  #   @api private
  attr_reader :password

  include R10K::Util::Setopts

  # Initialize the given source.
  #
  # @param name [String] The identifier for this source.
  # @param basedir [String] The base directory where the generated environments will be created.
  # @param options [Hash] An additional set of options for this source.
  #
  # @option options [Boolean] :prefix Whether to prefix the source name to the
  #   environment directory names. Defaults to false.
  # @option options [String] :remote The URL to the base directory of the SVN repository
  # @option options [String] :username The SVN username
  # @option options [String] :password The SVN password
  def initialize(name, basedir, options = {})
    super

    setopts(options, {:remote => :self, :username => :self, :password => :self})
    @environments = []
    @svn_remote = R10K::SVN::Remote.new(@remote, :username => @username, :password => @password)
  end

  # Enumerate the environments associated with this SVN source.
  #
  # @return [Array<R10K::Environment::SVN>] An array of environments created
  #   from this source.
  def environments
    if @environments.empty?
      @environments = generate_environments()
    end

    @environments
  end

  # Generate a list of currently available SVN environments
  #
  # @todo respect environment name corrections
  #
  # @api protected
  # @return [Array<R10K::Environment::SVN>] An array of environments created
  #   from this source.
  def generate_environments

    branch_names.map do |branch|
      options = {
        :remote   => branch.remote,
        :username => @username,
        :password => @password
      }
      R10K::Environment::SVN.new(branch.name, @basedir, branch.dirname, options)
    end
  end

  # List all environments that should exist in the basedir for this source
  # @note This is required by {R10K::Util::Basedir}
  # @return [Array<String>]
  def desired_contents
    @environments.map {|env| env.dirname }
  end

  include R10K::Logging

  private

  def branch_names
    branches = []

    branch_opts = {
      :prefix     => @prefix,
      :sourcename => @name,
    }

    branches << BranchName.new('production', "#{@remote}/trunk", branch_opts)
    @svn_remote.branches.each do |branch|
      branches << BranchName.new(branch, "#{@remote}/branches/#{branch}", branch_opts)
    end

    branches
  end

  # @api private
  # @todo respect environment name corrections
  class BranchName

    attr_reader :name
    attr_reader :remote

    def initialize(name, remote, opts)
      @name   = name
      @remote = remote
      @opts   = opts

      @prefix = opts[:prefix]
      @sourcename = opts[:sourcename]
    end

    def dirname
      dir = @name.dup

      if @prefix
        dir = "#{@sourcename}_#{dir}"
      end

      dir
    end
  end
end
