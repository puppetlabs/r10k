require 'r10k'
require 'r10k/module'
require 'r10k/errors'
require 'r10k/logging'

require 'systemu'
require 'semver'
require 'json'

class R10K::Module::Forge < R10K::Module

  def self.implements(name, args)
    args.is_a? String and SemVer.valid?(args)
  end

  include R10K::Logging

  def initialize(name, path, args)
    super

    @full_name = name

    @owner, @name = name.split('/')
    @version = SemVer.new(@args)
  end

  def sync!(options = {})
    return if insync?

    if File.exist? metadata_path
      cmd = []
      cmd << 'upgrade'
      cmd << "--version=#{@version}"
      cmd << "--ignore-dependencies"
      cmd << @full_name
      pmt cmd
    else
      cmd = []
      cmd << 'install'
      cmd << "--version=#{@version}"
      cmd << "--ignore-dependencies"
      cmd << @full_name
      pmt cmd
    end
  end

  private

  def insync?
    current_version = SemVer.new(metadata['version'])
  rescue
    false
  end

  def metadata
    JSON.parse(File.read(metadata_path))
  end

  def metadata_path
    File.join(full_path, 'metadata.json')
  end

  def pmt(args)
    cmd = "puppet module --modulepath '#{@path}' #{args.join(' ')}"
    logger.debug cmd
    status, stdout, stderr = systemu(cmd)
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
