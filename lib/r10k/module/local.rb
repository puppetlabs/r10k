require 'r10k/module'
require 'r10k/errors'
require 'r10k/logging'

require 'fileutils'
require 'systemu'
require 'json'
require 'tmpdir'

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
    if File.directory? @full_path
      logger.debug "Copy module to temporary directory"
      tmpdir = Dir.mktmpdir(@name, @basedir)
      FileUtils.cp_r File.join(@remote, '.'), tmpdir
      logger.debug "Remove old module directory and move new from temporary directory"
      FileUtils.rm_rf @full_path
      FileUtils.mv tmpdir @full_path
    else
      FileUtils.mkdir_p @full_path
      FileUtils.cp_r File.join(@remote,'.'), @full_path
    end
  end

  def version
    '0.0.1'   
  end

end