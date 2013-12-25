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

  # @!attribute [r] author
  #   @return [String] The Forge module author
  attr_reader :author

  # @deprecated
  def owner
    logger.warn "#{self.inspect}#owner is deprecated; use #author instead"
    @author
  end

  # @!attribute [r] full_name
  #   @return [String] The fully qualified module name
  attr_reader :full_name

  def initialize(name, basedir, args)
    @full_name = name
    @basedir   = basedir

    @author, @name = name.split('/')

    if args.is_a? String
      @expected_version = SemVer.new(args)
    end
  end

  def sync(options = {})
    return if insync?

    case status
    when :absent
      install
    when :outdated
      upgrade
    when :replaced
      reinstall
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

  # Determine the status of the forge module.
  #
  # @return [Symbol] :absent If the directory doesn't exist
  # @return [Symbol] :mismatched If the module is not a forge module, or
  #   isn't the right forge module
  # @return [Symbol] :outdated If the installed module is older than expected
  # @return [Symbol] :insync If the module is in the desired state
  def status
    if not File.exist?(metadata_path)
      # XXX THIS DOESN'T MATCH THE DOCUMENTATION
      :absent
    elsif @expected_version != version
      :outdated
    elsif ! matches_author?
      # XXX This needs to be evaluated before the version
      :replaced
    else
      :insync
    end
  end

  def metadata
    @metadata = JSON.parse(File.read(metadata_path)) rescue nil
  end

  def metadata_path
    File.join(full_path, 'metadata.json')
  end

  private

  def install
    FileUtils.mkdir @basedir unless File.directory? @basedir
    cmd = []
    cmd << 'install'
    cmd << "--version=#{@expected_version}" if @expected_version
    cmd << "--ignore-dependencies"
    cmd << @full_name
    pmt cmd
  end

  def upgrade
    cmd = []
    cmd << 'upgrade'
    cmd << "--version=#{@expected_version}" if @expected_version
    cmd << "--ignore-dependencies"
    cmd << @full_name
    pmt cmd
  end

  def reinstall
    FileUtils.rm_rf full_path
    install
  end

  def matches_author?
    @author == metadata_author
  end

  def metadata_author
    metadata['name'].split('-').first
  end

  include R10K::Execution

  def pmt(args)
    cmd = "puppet module --modulepath '#{@basedir}' #{args.join(' ')}"
    log_event = "puppet module #{args.join(' ')}, modulepath: #{@basedir.inspect}"

    execute(cmd, :event => log_event)
  end
end
