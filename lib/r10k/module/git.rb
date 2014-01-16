require 'r10k/module'
require 'r10k/git/working_dir'

class R10K::Module::Git < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a? Hash and args.has_key?(:git)
  rescue
    false
  end

  def initialize(name, basedir, args)
    @name, @basedir, @args = name, basedir, args

    @remote = @args[:git]
    @ref    = (@args[:ref] || 'master')

    @working_dir = R10K::Git::WorkingDir.new(@ref, @remote, @basedir, @name)
  end

  def version
    @ref
  end

  def sync
    @working_dir.sync
  end

  def status
    if not @working_dir.exist?
      :absent
    elsif not @working_dir.git?
      :mismatched
    elsif not @remote == @working_dir.remote
      :mismatched
    else
      :insync
    end
  end
end
