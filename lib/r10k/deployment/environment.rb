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
    @dirname = sanitize_dirname(dirname || ref)

    @working_dir = R10K::Git::WorkingDir.new(@ref, @remote, @basedir, @dirname)

    @full_path = File.join(@basedir, @dirname)
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
      mod.sync
    end
  end

  def puppetfile
    @puppetfile ||= R10K::Puppetfile.new(@full_path)
  end

  def modules
    puppetfile.load
    puppetfile.modules
  end

  private

  # Strip out non-word characters in an environment directory name
  #
  # Puppet can only use word characers (letter, digit, underscore) in
  # environment names; this cleans up environment names to avoid traversals
  # and similar issues.
  #
  # @param input [String] The raw branch name
  #
  # @return [String] The sanitized branch dirname
  def sanitize_dirname(input)
    output  = input.dup
    invalid = %r[\W+]
    if output.gsub!(invalid, '_')
      logger.warn "Environment #{input.inspect} contained non-word characters; sanitizing to #{output.inspect}"
    end

    output
  end
end
end
end
