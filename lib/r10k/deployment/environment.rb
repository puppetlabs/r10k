require 'r10k/module'
require 'r10k/logging'

module R10K
class Deployment
class Environment

  include R10K::Logging

  # @!attribute [r] ref
  #   The git ref to instantiate into the basedir
  attr_reader :ref

  # @!attribute [r] remote
  #   The location of the remote git repository
  attr_reader :remote

  # @!attribute [r] basedir
  #   The basedir to clone the root into
  attr_reader :basedir

  # @!attribute [r] dirname
  #   @return [String] The directory name to use for the environment
  attr_reader :dirname

  # @param [String] ref
  # @param [String] remote
  # @param [String] basedir
  # @param [String] dirname The directory to clone the root into, defaults to ref
  def initialize(ref, remote, basedir, dirname = nil)
    @ref     = ref
    @remote  = remote
    @basedir = basedir
    @dirname = dirname || ref

    @working_dir = R10K::Git::WorkingDir.new(@ref, @remote, @basedir, @dirname)

    @full_path = File.join(@basedir, @dirname)
  end

  def sync(options = {})
    recursive_needed = !(@working_dir.cloned?)
    @working_dir.sync

    sync_modules!(options) if recursive_needed
  end

  def sync_modules!(options = {})
    modules.each do |mod|
      mod.sync(options)
    end
  end

  def puppetfile
    @puppetfile = R10K::Puppetfile.new(@full_path)
  end

  def modules
    puppetfile.load
    puppetfile.modules
  end
end
end
end
