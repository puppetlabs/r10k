require 'r10k/module'
require 'r10k/errors'
require 'r10k/logging'

require 'fileutils'
require 'systemu'
require 'r10k/semver'
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
    @full_name = name
    @basedir   = basedir
    @args      = name, basedir, args
    @remote    = args[:path]

  end

  def sync(options = {})
    return if insync?

    if insync?
      logger.debug1 "Module #{@full_name} already matches version #{@version}"
    elsif File.exist? metadata_path
      logger.debug "Module #{@full_name} is installed but doesn't match version #{@version}, upgrading"

      # A Pulp based puppetforge http://www.pulpproject.org/ wont support
      # `puppet module install abc/xyz --version=v1.5.9` but puppetlabs forge
      # will support `puppet module install abc/xyz --version=1.5.9`
      #
      # Removing v from the semver for constructing the command ensures
      # compatibility across both
      FileUtils.cp_r @remote, @basedir
    else
      FileUtils.mkdir @basedir unless File.directory? @basedir
      FileUtils.mkdir full_path
      logger.debug "Module #{@full_name} is not installed"
      FileUtils.cp_r @remote/., @basedir
    end
  end

  # @return [SemVer, NilClass]
  def version
    if metadata
      SemVer.new(metadata['version'])
    else
      SemVer::MIN
    end
  end

  def insync?
    @version == version
  end

  def metadata
    @metadata = JSON.parse(File.read(metadata_path)) rescue nil
  end

  def metadata_path
    File.join(full_path, 'metadata.json')
  end

end
