require 'pathname'
require 'r10k/module'
require 'r10k/util/purgeable'
require 'r10k/errors'
require 'r10k/formatter/base_formatter'
require 'r10k/formatter/classic_puppetfile'

require 'r10k/plugin_loader'

module R10K
class Puppetfile
  # Defines the data members of a Puppetfile

  include R10K::Logging
  include R10K::PluginLoader

  # @!attribute [r] forge
  #   @return [String] The URL to use for the Puppet Forge
  attr_reader :forge

  # @!attribute [r] modules
  #   @return [Array<R10K::Module>]
  attr_reader :modules

  # @!attribute [r] basedir
  #   @return [String] The base directory that contains the Puppetfile
  attr_reader :basedir

  # @!attribute [r] moduledir
  #   @return [String] The directory to install the modules #{basedir}/modules
  attr_reader :moduledir

  # @!attrbute [r] puppetfile_path
  #   @return [String] The path to the Puppetfile
  attr_reader :puppetfile_path

  # @!attribute [rw] environment
  #   @return [R10K::Environment] Optional R10K::Environment that this Puppetfile belongs to.
  attr_accessor :environment

  attr_accessor :formatter


  # @param [String] basedir
  # @param [String] moduledir The directory to install the modules, default to #{basedir}/modules
  # @param [String] puppetfile_path The path to the Puppetfile, default to #{basedir}/Puppetfile
  # @param [String] puppetfile_name The name of the Puppetfile, default to 'Puppetfile'
  def initialize(basedir, moduledir = nil, puppetfile_path = nil, puppetfile_name = nil )
    @basedir         = basedir
    @moduledir       = moduledir  || File.join(basedir, 'modules')
    @puppetfile_name = puppetfile_name || 'Puppetfile'
    @puppetfile_path = puppetfile_path || File.join(basedir, @puppetfile_name)
    logger.info _("Using Puppetfile '%{puppetfile}'") % {puppetfile: @puppetfile_path}

    @modules = []
    @managed_content = {}
    @forge   = 'forgeapi.puppetlabs.com'
  end

  # @param [String] forge
  def set_forge(forge)
    @forge = forge
  end

  # @param [String] moduledir
  def set_moduledir(moduledir)
    @moduledir = if Pathname.new(moduledir).absolute?
      moduledir
    else
      File.join(basedir, moduledir)
    end
  end

  # @param [String] name
  # @param [*Object] args
  def add_module(name, args)
    if args.is_a?(Hash) && install_path = args.delete(:install_path)
      install_path = resolve_install_path(install_path)
      validate_install_path(install_path, name)
    else
      install_path = @moduledir
    end

    # Keep track of all the content this Puppetfile is managing to enable purging.
    @managed_content[install_path] = Array.new unless @managed_content.has_key?(install_path)
    mod = R10K::Module.new(name, install_path, args, @environment)

    @managed_content[install_path] << mod.name
    @modules << mod
  end


  def loaded?
    ! @managed_content.empty?
  end

  include R10K::Util::Purgeable

  def managed_directories
    formatter.load_content unless loaded?
    # the managed_content is populated during the loading of the content
    @managed_content.keys
  end

  # @return [R10K::Formatter::BaseFormmater] - the formatter found by cycling through each formatter for a compatible type
  # @note While we currently load self inside the formatter, we should instead reverse this allow the base formatter
  # to create a contract for all other formatters in which this class should then utilize
  # This was done intentionally to not have to perform a major refactor of this class
  # @note if no formatter was found with the formatter_type specified, we default to the classic format that we all know and love
  def formatter
    begin
      @formatter ||= first_formatter(puppetfile_path).new(puppetfile_path, self)
    rescue R10K::NoFormatterError => e
      # no puppetfile found with the format type specified, switching to default
      @formatter = R10K::Formatter::ClassicPuppetfile.new(puppetfile_path, self)
    end
  end

  # Returns an array of the full paths to all the content being managed.
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    formatter.load_content unless loaded?
    # the managed_content is populated during the loading of the content
    @managed_content.flat_map do |install_path, modnames|
      modnames.collect { |name| File.join(install_path, name) }
    end
  end

  # @return [Array<String>] - loads the contents of the puppet file which produces a list of modules
  def modules
    unless @modules.empty?
      formatter.load_content unless loaded?
    end
    @modules
  end

  def purge_exclusions
    exclusions = managed_directories

    if environment && environment.respond_to?(:desired_contents)
      exclusions += environment.desired_contents
    end

    exclusions
  end

  def accept(visitor)
    visitor.visit(:puppetfile, self) do
      modules.each do |mod|
        mod.accept(visitor)
      end
    end
  end

  private

  def resolve_install_path(path)
    pn = Pathname.new(path)

    unless pn.absolute?
      pn = Pathname.new(File.join(basedir, path))
    end

    # .cleanpath is as good as we can do without touching the filesystem.
    # The .realpath methods will also choke if some of the intermediate
    # paths are missing, even though we will create them later as needed.
    pn.cleanpath.to_s
  end

  def validate_install_path(path, modname)
    real_basedir = Pathname.new(basedir).cleanpath.to_s

    unless /^#{Regexp.escape(real_basedir)}.*/ =~ path
      raise R10K::Error.new("Puppetfile cannot manage content '#{modname}' outside of containing environment: #{path} is not within #{real_basedir}")
    end

    true
  end
end
end
