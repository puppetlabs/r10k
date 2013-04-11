require 'r10k'
require 'r10k/module'
require 'r10k/git/working_dir'

class R10K::Module::Git
  include R10K::Module

  def self.implement?(name, args)
    args.is_a? Hash and args.has_key?(:git)
  rescue
    false
  end

  def initialize(name, path, args)
    @name, @path, @args = name, path, args

    @remote = @args[:git]
    @ref    = (@args[:ref] || 'master')
  end

  def sync!(options = {})
    working_dir = R10K::Git::WorkingDir.new(@remote)
    working_dir.sync(full_path, @ref, options)
  end
end
