require 'r10k/module'
require 'r10k/errors'
require 'r10k/logging'

require 'fileutils'
require 'systemu'
require 'json'

class R10K::Module::Local < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a? Hash and args.has_key?(:path)
  rescue
    false
  end

  include R10K::Logging

  attr_accessor :owner, :full_name

  def initialize(name, basedir, args)
    @name, @basedir, @args = name, basedir, args
    
    @full_path = File.join(@basedir, @name)
    @remote    = File.expand_path(args[:path])
  end

  def sync(options = {})
    logger.debug "Always install local Module #{@full_name}"
    FileUtils.mkdir @basedir unless File.directory? @basedir
    FileUtils.mkdir_p @full_path unless File.directory? @full_path
    FileUtils.cp_r File.join(@remote,'.'), @full_path
  end

  def version
    '0.0.1'   
  end

end