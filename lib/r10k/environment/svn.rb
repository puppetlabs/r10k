require 'r10k/puppetfile'
require 'r10k/svn/working_dir'

class R10K::Environment::SVN < R10K::Environment::Base

  include R10K::Logging

  # @!attribute [r] remote
  #   @return [String] The URL to the remote SVN branch to check out
  attr_reader :remote

  # @!attribute [r] working_dir
  #   @api private
  #   @return [R10K::SVN::WorkingDir] The SVN working directory backing this environment
  attr_reader :working_dir

  # @!attribute [r] puppetfile
  #   @api public
  #   @return [R10K::Puppetfile] The puppetfile instance associated with this environment
  attr_reader :puppetfile

  def initialize(name, basedir, dirname, options = {})
    super

    @remote = options[:remote]

    @working_dir = R10K::SVN::WorkingDir.new(Pathname.new(@full_path))
    @puppetfile  = R10K::Puppetfile.new(@full_path)
  end

  def sync
    if @working_dir.is_svn?
      @working_dir.update
    else
      @working_dir.checkout(@remote)
      logger.debug "Environment #{@full_path} is a fresh clone; automatically updating modules."
      sync_modules
    end
  end

  def modules
    @puppetfile.load
    @puppetfile.modules
  end

  def sync_modules
    modules.each do |mod|
      logger.debug "Deploying module #{mod.name}"
      mod.sync
    end
  end
end
