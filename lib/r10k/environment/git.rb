require 'r10k/logging'
require 'r10k/puppetfile'
require 'r10k/git/working_dir'

class R10K::Environment::Git < R10K::Environment::Base

  include R10K::Logging

  # @!attribute [r] remote
  #   @return [String] The URL to the remote git repository
  attr_reader :remote

  # @!attribute [r] ref
  #   @return [String] The git reference to use for this environment
  attr_reader :ref

  # @!attribute [r] working_dir
  #   @api private
  #   @return [R10K::Git::WorkingDir] The git working directory backing this environment
  attr_reader :working_dir

  # @!attribute [r] puppetfile
  #   @api public
  #   @return [R10K::Puppetfile] The puppetfile instance associated with this environment
  attr_reader :puppetfile

  def initialize(name, basedir, dirname, options = {})
    super
    @remote = options[:remote]
    @ref    = options[:ref]

    @working_dir = R10K::Git::WorkingDir.new(@ref, @remote, @basedir, @dirname)
    @puppetfile  = R10K::Puppetfile.new(@full_path)
  end


  def sync
    recursive_needed = !(@working_dir.cloned?)
    @working_dir.sync

    if recursive_needed
      logger.debug "Environment #{@full_path} is a fresh clone; automatically updating modules."
      sync_modules
    end
  end

  def sync_modules
    modules.each do |mod|
      logger.debug "Deploying module #{mod.name}"
      mod.sync
    end
  end

  def modules
    @puppetfile.load
    @puppetfile.modules
  end
end
