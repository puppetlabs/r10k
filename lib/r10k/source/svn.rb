require 'r10k/svn'
require 'r10k/environment'
require 'r10k/util/purgeable'
require 'r10k/util/core_ext/hash_ext'

class R10K::Source::SVN < R10K::Source::Base

  R10K::Source.register(:svn, self)

  # @!attribute [r] remote
  #   @return [String] The URL to the base directory of the SVN repository
  attr_reader :remote

  # @!attribute [r] svn_remote
  #   @api private
  #   @return [R10K::SVN::Remote]
  attr_reader :svn_remote

  def initialize(basedir, name, options = {})
    super

    @remote = options[:remote]
    @environments = []

    @svn_remote = R10K::SVN::Remote.new(@remote)
  end

  def environments
    if @environments.empty?
      @environments = generate_environments()
    end

    @environments
  end

  # Generate a list of currently available SVN environments
  #
  # @todo respect environment prefixing
  # @todo respect environment name corrections
  def generate_environments
    paths = []

    @svn_remote.branch_paths.each do |remote_path|
      paths << remote_path
    end
    paths << R10K::SVN::Remote::Path.new('production', @remote, @svn_remote.trunk)

    paths.map do |path|
      R10K::Environment::SVN.new(path.name, @basedir, path.name,
                                 { :remote => path.url })
    end
  end

  include R10K::Util::Purgeable

  def managed_directory
    @basedir
  end

  def current_contents
    Dir.glob(File.join(@basedir, '*')).map do |fname|
      File.basename fname
    end
  end

  # List all environments that should exist in the basedir for this source
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    @environments.map {|env| env.dirname }
  end

  include R10K::Logging
end
