require 'r10k/module'
require 'r10k/errors'
require 'r10k/logging'
require 'r10k/execution'
require 'r10k/module/metadata'
require 'r10k/module_repository/forge'

require 'pathname'
require 'fileutils'
require 'semver'

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

  def initialize(full_name, basedir, args)
    @full_name = full_name
    @basedir   = basedir

    @author, @name = full_name.split('/')

    @full_path = Pathname.new(File.join(@basedir, @name))

    @metadata = R10K::Module::Metadata.new(@full_path + 'metadata.json')

    if args.is_a? String
      @expected_version = SemVer.new(args)
    elsif args.is_a? Symbol and args == :latest
      @expected_version = args
    end
  end

  def sync(options = {})
    case status
    when :absent
      install
    when :outdated
      upgrade
    when :mismatched
      reinstall
    end
  end

  # @return [SemVer] The expected version that the module
  attr_reader :expected_version

  # @return [SemVer] The version of the currently installed module
  def current_version
    @metadata.version
  end

  alias version current_version

  def exist?
    @full_path.exist?
  end

  def insync?
    status == :insync
  end

  # Determine the status of the forge module.
  #
  # @return [Symbol] :absent If the directory doesn't exist
  # @return [Symbol] :mismatched If the module is not a forge module, or
  #   isn't the right forge module
  # @return [Symbol] :outdated If the installed module is older than expected
  # @return [Symbol] :insync If the module is in the desired state
  def status
    if not self.exist?
      # The module is not installed
      return :absent
    elsif not @metadata.exist?
      # The directory exists but doesn't have a metadata file; it probably
      # isn't a forge module.
      return :mismatched
    elsif not @author == @metadata.author
      # This is a forge module but the installed module is a different author
      # than the expected author.
      return :mismatched
    end

    # The module is installed is the right author, but we may need to determine
    # which version to install.
    if @expected_version == :latest
      set_version_from_forge
    end

    if @expected_version != @metadata.version
      return :outdated
    end

    return :insync
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

  def uninstall
    FileUtils.rm_rf full_path
  end

  def reinstall
    uninstall
    install
  end

  include R10K::Execution

  def pmt(args)
    cmd = "puppet module --modulepath '#{@basedir}' #{args.join(' ')}"
    log_event = "puppet module #{args.join(' ')}, modulepath: #{@basedir.inspect}"

    execute(cmd, :event => log_event)
  end

  def set_version_from_forge
    repo = R10K::ModuleRepository::Forge.new
    expected = repo.latest_version(@full_name)
    @expected_version = SemVer.new(expected)
  end
end
