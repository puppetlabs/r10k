require 'r10k/module'
require 'r10k/errors'
require 'r10k/logging'
require 'r10k/execution'

require 'fileutils'
require 'semver'
require 'json'

class R10K::Module::Forge < R10K::Module::Base

  R10K::Module.register(self)

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
      @expected_version = SemVer.new(args)
    end
  end

  def sync(options = {})
    return if insync?

    if insync?

    elsif File.exist? metadata_path

      cmd = []
      cmd << 'upgrade'
      cmd << "--version=#{@expected_version}" if @expected_version
      cmd << "--ignore-dependencies"
      cmd << @full_name
      pmt cmd
    else
      FileUtils.mkdir @basedir unless File.directory? @basedir
      cmd = []
      cmd << 'install'
      cmd << "--version=#{@expected_version}" if @expected_version
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
    @expected_version == version
  end

  def metadata
    @metadata = JSON.parse(File.read(metadata_path)) rescue nil
  end

  def metadata_path
    File.join(full_path, 'metadata.json')
  end

  private

  include R10K::Execution

  def pmt(args)
    cmd = "puppet module --modulepath '#{@basedir}' #{args.join(' ')}"
    log_event = "puppet module #{args.join(' ')}, modulepath: #{@basedir.inspect}"

    execute(cmd, :event => log_event)
  end
end
