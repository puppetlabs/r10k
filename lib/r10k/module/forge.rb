require 'r10k'
require 'r10k/module'
require 'r10k/errors'
require 'r10k/logging'

require 'fileutils'
require 'systemu'
require 'semver'
require 'json'

module R10K
module Module
class Forge

  include R10K::Module

  def self.implement?(name, args)
    !!(name.match %r[\w+/\w+])
  end

  include R10K::Logging

  attr_accessor :owner, :full_name

  def initialize(name, basedir, args)
    @full_name = name
    @basedir   = basedir

    @owner, @name = name.split('/')

    if args.is_a? String
      @version = SemVer.new(args)
    end
  end

  def sync(options = {})
    return if insync?

    if insync?
      #logger.debug1 "Module #{@full_name} already matches version #{@version}"
    elsif File.exist? metadata_path
      #logger.debug "Module #{@full_name} is installed but doesn't match version #{@version}, upgrading"
      cmd = []
      cmd << 'upgrade'
      cmd << "--version=#{@version}" if @version
      cmd << "--ignore-dependencies"
      cmd << @full_name
      pmt cmd
    else
      FileUtils.mkdir @basedir unless File.directory? @basedir
      #logger.debug "Module #{@full_name} is not installed"
      cmd = []
      cmd << 'install'
      cmd << "--version=#{@version}" if @version
      cmd << "--ignore-dependencies"
      cmd << @full_name
      pmt cmd
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

  private

  def pmt(args)
    cmd = "puppet module --modulepath '#{@basedir}' #{args.join(' ')}"
    log_event = "puppet module #{args.join(' ')}, modulepath: #{@basedir.inspect}"
    logger.debug1 "Execute: #{cmd}"

    status, stdout, stderr = systemu(cmd)

    logger.debug2 "[#{log_event}] STDOUT: #{stdout.chomp}" unless stdout.empty?
    logger.debug2 "[#{log_event}] STDERR: #{stderr.chomp}" unless stderr.empty?

    unless status == 0
      e = R10K::ExecutionFailure.new("#{cmd.inspect} returned with non-zero exit value #{status.inspect}")
      e.exit_code = status
      e.stdout    = stdout
      e.stderr    = stderr
      raise e
    end
    stdout
  end
end
end
end
