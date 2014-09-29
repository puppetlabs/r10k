require 'r10k/module'
require 'r10k/errors'
require 'r10k/module/metadata'
require 'r10k/util/subprocess'
require 'r10k/module_repository/forge'

require 'pathname'
require 'fileutils'
require 'r10k/semver'

class R10K::Module::Forge < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    !!(name.match %r[\w+/\w+])
  end

  include R10K::Logging

  def initialize(title, dirname, args)
    super
    @metadata = R10K::Module::Metadata.new(path + 'metadata.json')

    if args.is_a? String
      @expected_version = R10K::SemVer.new(args)
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

  # @return [R10K::SemVer] The expected version that the module
  def expected_version
    if @expected_version == :latest
      set_version_from_forge
    end
    @expected_version
  end


  # @return [R10K::SemVer] The version of the currently installed module
  def current_version
    @metadata.version
  end

  alias version current_version

  def exist?
    path.exist?
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
    end

    # The module is present and has a metadata file, read the metadata to
    # determine the state of the module.
    @metadata.read

    if not @owner == @metadata.author
      # This is a forge module but the installed module is a different author
      # than the expected author.
      return :mismatched
    end

    if expected_version && (expected_version != @metadata.version)
      return :outdated
    end

    return :insync
  end

  private

  def install
    FileUtils.mkdir @dirname unless File.directory? @dirname
    cmd = []
    cmd << 'install'
    cmd << "--version=#{expected_version}" if expected_version
    cmd << "--force"
    cmd << title
    pmt cmd
  end

  def upgrade
    cmd = []
    cmd << 'upgrade'
    cmd << "--version=#{expected_version}" if expected_version
    cmd << "--force"
    cmd << title
    pmt cmd
  end

  def uninstall
    FileUtils.rm_rf full_path
  end

  def reinstall
    uninstall
    install
  end

  # Wrap puppet module commands
  #
  # @param argv [Array<String>]
  #
  # @return [String] The stdout from the executed command
  def pmt(argv)
    argv = ['puppet', 'module', '--modulepath', @dirname] + argv

    subproc = R10K::Util::Subprocess.new(argv)
    subproc.raise_on_fail = true
    subproc.logger = self.logger

    result = subproc.execute

    result.stdout
  end

  def set_version_from_forge
    repo = R10K::ModuleRepository::Forge.new
    expected = repo.latest_version(title)
    @expected_version = R10K::SemVer.new(expected)
  end

  # Override the base #parse_title to ensure we have a fully qualified name
  def parse_title(title)
    if (match = title.match(/\A(\w+)[-\/](\w+)\Z/))
      [match[1], match[2]]
    else
      raise ArgumentError, "Forge module names must match 'owner/modulename'"
    end
  end
end
