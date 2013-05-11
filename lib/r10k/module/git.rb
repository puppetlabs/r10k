require 'r10k'
require 'r10k/module'
require 'r10k/git/working_dir'
require 'forwardable'

module R10K
module Module
class Git
  include R10K::Module

  def self.implement?(name, args)
    args.is_a? Hash and args.has_key?(:git)
  rescue
    false
  end

  extend Forwardable
  def_delegator :@working_dir, :sync

  def initialize(name, basedir, args)
    @name, @basedir, @args = name, basedir, args

    @remote = @args[:git]
    @ref    = (@args[:ref] || 'master')

    @working_dir = R10K::Git::WorkingDir.new(@ref, @remote, @basedir, @name)
  end

  def version
    @ref
  end
end
end
end
