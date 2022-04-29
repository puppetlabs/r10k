require 'r10k/svn'
require 'r10k/environment'
require 'r10k/environment/name'
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

  # @!attribute [r] ignore_branch_prefixes
  #   @return [Array<String>] Array of strings used to remove repository branches
  #     that will be deployed as environments.
  attr_reader :ignore_branch_prefixes

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
  # @option options [Array<String>] :ignore_branch_prefixes Prefixes of branches that should not be deployed
  # @option options [String] :username The SVN username
  # @option options [String] :password The SVN password
  # @option options [String] :puppetfile_name The puppetfile name
  def initialize(name, basedir, options = {})
    super

    setopts(options, {
      :remote => :self,
      :ignore_branch_prefixes => :self,
      :username => :self,
      :password => :self,
      :puppetfile_name => :self
    }, raise_on_unhandled: false)

    @environments = []
    @svn_remote = R10K::SVN::Remote.new(@remote, :username => @username, :password => @password)
  end

  def reload!
    @environments = generate_environments()
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
    names_and_paths.map do |(branch, path)|
      options = {
        :remote   => path,
        :username => @username,
        :password => @password,
        :puppetfile_name => puppetfile_name
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

  def filter_branches(branches, ignore_prefixes)
    filter = Regexp.new("^(#{ignore_prefixes.join('|')})")
    branches = branches.reject do |branch|
      result = filter.match(branch)
      if result
        logger.warn _("Branch %{branch} filtered out by ignore_branch_prefixes %{ibp}") % {branch: branch, ibp: @ignore_branch_prefixes}
      end
      result
    end
    branches
  end

  private

  def names_and_paths
    branches = []
    opts = {prefix: @prefix,
            correct: false,
            validate: false,
            source: @name,
            strip_component: @strip_component}
    branches << [R10K::Environment::Name.new('production', opts), "#{@remote}/trunk"]
    additional_branch_names = @svn_remote.branches
    if @ignore_branch_prefixes && !@ignore_branch_prefixes.empty?
      additional_branch_names = filter_branches(additional_branch_names, @ignore_branch_prefixes)
    end

    additional_branch_names.each do |branch|
      branches << [R10K::Environment::Name.new(branch, opts), "#{@remote}/branches/#{branch}"]
    end
    branches
  end
end
