require 'r10k'
require 'r10k/module'
require 'r10k/errors'
require 'r10k/logging'

require 'systemu'
require 'semver'
require 'json'

class R10K::Module::Forge

  include R10K::Module

  def self.implement?(name, args)
    !!(name.match(%r[\w+/\w+]) and args.is_a? String and SemVer.valid?(args))
  end

  include R10K::Logging

  attr_accessor :version, :owner, :full_name

  def initialize(name, path, args)
    @full_name = name
    @path      = path

    @owner, @name = name.split('/')
    @version = SemVer.new(args)
  end

  def sync!(options = {})
    return if insync?

    if insync?
      logger.debug1 "Module #{@full_name} already matches version #{@version}"
    elsif File.exist? metadata_path
      logger.debug "Module #{@full_name} is installed but doesn't match version #{@version}, upgrading"
      cmd = []
      cmd << 'upgrade'
      cmd << "--version=#{@version}"
      cmd << "--ignore-dependencies"
      cmd << @full_name
      pmt cmd
    else
      logger.debug "Module #{@full_name} is not installed"
      cmd = []
      cmd << 'install'
      cmd << "--version=#{@version}"
      cmd << "--ignore-dependencies"
      cmd << @full_name
      pmt cmd
    end
  end

  def current_version
    SemVer.new(metadata['version'])
  end

  def insync?
    @version == current_version
  rescue
    false
  end

  def metadata
    JSON.parse(File.read(metadata_path))
  end

  def metadata_path
    File.join(full_path, 'metadata.json')
  end

  private

  def pmt(args)
    cmd = "puppet module --modulepath '#{@path}' #{args.join(' ')}"
    log_event = "puppet module #{args.join(' ')}, modulepath: #{@path.inspect}"
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
