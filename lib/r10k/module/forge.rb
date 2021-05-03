require 'r10k/module'
require 'r10k/errors'
require 'r10k/module/metadata_file'

require 'r10k/forge/module_release'

require 'pathname'
require 'fileutils'
require 'puppet_forge/util'

class R10K::Module::Forge < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args[:type].to_s == 'forge' ||
      (!!
       ((args.keys & %i{git svn type}).empty? &&
        args.has_key?(:version) &&
        name.match(%r[\w+[/-]\w+]) &&
        valid_version?(args[:version])))
  end

  def self.valid_version?(expected_version)
    expected_version == :latest || expected_version.nil? || PuppetForge::Util.version_valid?(expected_version)
  end

  # @!attribute [r] metadata
  #   @api private
  #   @return [PuppetForge::Metadata]
  attr_reader :metadata

  # @!attribute [r] v3_module
  #   @api private
  #   @return [PuppetForge::V3::Module] The Puppet Forge module metadata
  attr_reader :v3_module

  include R10K::Logging

  include R10K::Util::Setopts

  def initialize(title, dirname, opts, environment=nil)
    super

    @metadata_file = R10K::Module::MetadataFile.new(path + 'metadata.json')
    @metadata = @metadata_file.read

    setopts(opts, {
      # Standard option interface
      :version   => :expected_version,
      :source    => ::R10K::Util::Setopts::Ignore,
      :type      => ::R10K::Util::Setopts::Ignore,
      :overrides => :self,
    })

    @expected_version ||= current_version || :latest

    @v3_module = PuppetForge::V3::Module.new(:slug => @title)
  end

  # @param [Hash] opts Deprecated
  def sync(opts={})
    super

    case status
    when :absent
      install
    when :outdated
      upgrade
    when :mismatched
      reinstall
    end
  end

  def properties
    {
      :expected => expected_version,
      :actual   => current_version,
      :type     => :forge,
    }
  end

  # @return [String] The expected version that the module
  def expected_version
    if @expected_version == :latest
      begin
        @expected_version = @v3_module.current_release.version
      rescue Faraday::ResourceNotFound => e
        raise PuppetForge::ReleaseNotFound, _("The module %{title} does not exist on %{url}.") % {title: @title, url: PuppetForge::V3::Release.conn.url_prefix}, e.backtrace
      end
    end
    @expected_version
  end

  # @return [String] The version of the currently installed module
  def current_version
    if insync?
      (@metadata ||= @metadata_file.read).nil? ? nil : @metadata.version
    else
      nil
    end
  end

  alias version current_version

  def exist?
    path.exist?
  end

  def insync?
    status == :insync
  end

  def deprecated?
    begin
      @v3_module.fetch && @v3_module.has_attribute?('deprecated_at') && !@v3_module.deprecated_at.nil?
    rescue Faraday::ResourceNotFound => e
      raise PuppetForge::ReleaseNotFound, _("The module %{title} does not exist on %{url}.") % {title: @title, url: PuppetForge::V3::Release.conn.url_prefix}, e.backtrace
    end
  end

  # Determine the status of the forge module.
  #
  # @return [Symbol] :absent If the directory doesn't exist
  # @return [Symbol] :mismatched If the module is not a forge module, or
  #   isn't the right forge module
  # @return [Symbol] :mismatched If the module was previously a git checkout
  # @return [Symbol] :outdated If the installed module is older than expected
  # @return [Symbol] :insync If the module is in the desired state
  def status
    if not self.exist?
      # The module is not installed
      return :absent
    elsif not File.exist?(@path + 'metadata.json')
      # The directory exists but doesn't have a metadata file; it probably
      # isn't a forge module.
      return :mismatched
    end

    if File.directory?(@path + '.git')
      return :mismatched
    end

    # The module is present and has a metadata file, read the metadata to
    # determine the state of the module.
    @metadata = @metadata_file.read(@path + 'metadata.json')

    if not @title.tr('/','-') == @metadata.full_module_name.tr('/','-')

      # This is a forge module but the installed module is a different author
      # than the expected author.
      return :mismatched
    end

    if expected_version && (expected_version != @metadata.version)
      return :outdated
    end

    return :insync
  end

  def install
    if deprecated?
      logger.warn "Puppet Forge module '#{@v3_module.slug}' has been deprecated, visit https://forge.puppet.com/#{@v3_module.slug.tr('-','/')} for more information."
    end

    parent_path = @path.parent
    if !parent_path.exist?
      parent_path.mkpath
    end
    module_release = R10K::Forge::ModuleRelease.new(@title, expected_version)
    module_release.install(@path)
  end

  alias upgrade install

  def uninstall
    FileUtils.rm_rf full_path
  end

  def reinstall
    uninstall
    install
  end

  private

  # Override the base #parse_title to ensure we have a fully qualified name
  def parse_title(title)
    if (match = title.match(/\A(\w+)[-\/](\w+)\Z/))
      [match[1], match[2]]
    else
      raise ArgumentError, _("Forge module names must match 'owner/modulename', instead got #{title}")
    end
  end
end
