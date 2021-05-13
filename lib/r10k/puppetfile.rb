require 'thread'
require 'pathname'
require 'r10k/module'
require 'r10k/util/purgeable'
require 'r10k/errors'
require 'r10k/content_synchronizer'
require 'r10k/module_loader/puppetfile/dsl'

module R10K
class Puppetfile
  # Defines the data members of a Puppetfile

  include R10K::Settings::Mixin

  def_setting_attr :pool_size, 4

  include R10K::Logging

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

  # @!attribute [rw] force
  #   @return [Boolean] Overwrite any locally made changes
  attr_accessor :force

  # @!attribute [r] overrides
  #   @return [Hash] Various settings overridden from normal configs
  attr_reader :overrides

  # @param [String] basedir
  # @param [Hash, String, nil] options_or_moduledir The directory to install the modules or a Hash of options.
  #         Usage as moduledir is deprecated. Only use as options, defaults to nil
  # @param [String, nil] puppetfile_path Deprecated - The path to the Puppetfile, defaults to nil
  # @param [String, nil] puppetfile_name Deprecated - The name of the Puppetfile, defaults to nil
  # @param [Boolean, nil] force Deprecated - Shall we overwrite locally made changes?
  def initialize(basedir, options_or_moduledir = nil, deprecated_path_arg = nil, deprecated_name_arg = nil, deprecated_force_arg = nil)
    @basedir         = basedir
    if options_or_moduledir.is_a? Hash
      options = options_or_moduledir
      deprecated_moduledir_arg = nil
    else
      options = {}
      deprecated_moduledir_arg = options_or_moduledir
    end

    @force           = deprecated_force_arg     || options.delete(:force)           || false
    @moduledir       = deprecated_moduledir_arg || options.delete(:moduledir)       || File.join(basedir, 'modules')
    @puppetfile_name = deprecated_name_arg      || options.delete(:puppetfile_name) || 'Puppetfile'
    @puppetfile_path = deprecated_path_arg      || options.delete(:puppetfile_path) || File.join(basedir, @puppetfile_name)

    @overrides       = options.delete(:overrides) || {}

    logger.info _("Using Puppetfile '%{puppetfile}'") % {puppetfile: @puppetfile_path}

    @modules = []
    @managed_content = {}
    @forge   = 'forgeapi.puppetlabs.com'

    @loaded = false
  end

  def load(default_branch_override = nil)
    return true if self.loaded?
    if File.readable? @puppetfile_path
      self.load!(default_branch_override)
    else
      logger.debug _("Puppetfile %{path} missing or unreadable") % {path: @puppetfile_path.inspect}
    end
  end

  def load!(default_branch_override = nil)
    @default_branch_override = default_branch_override

    dsl = R10K::ModuleLoader::Puppetfile::DSL.new(self)
    dsl.instance_eval(puppetfile_contents, @puppetfile_path)

    validate_no_duplicate_names(@modules)
    @loaded = true
  rescue SyntaxError, LoadError, ArgumentError, NameError => e
    raise R10K::Error.wrap(e, _("Failed to evaluate %{path}") % {path: @puppetfile_path})
  end

  def loaded?
    @loaded
  end

  # @param [Array<String>] modules
  def validate_no_duplicate_names(modules)
    dupes = modules
            .group_by { |mod| mod.name }
            .select { |_, v| v.size > 1 }
            .map(&:first)
    unless dupes.empty?
      msg = _('Puppetfiles cannot contain duplicate module names.')
      msg += ' '
      msg += _("Remove the duplicates of the following modules: %{dupes}" % { dupes: dupes.join(' ') })
      raise R10K::Error.new(msg)
    end
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
  # @param [Hash, String, Symbol] args Calling with anything but a Hash is
  #   deprecated. The DSL will now convert String and Symbol versions to
  #   Hashes of the shape
  #     { version: <String or Symbol> }
  #
  def add_module(name, args)
    if !args.is_a?(Hash)
      args = { version: args }
    end

    args[:overrides] = @overrides

    if install_path = args.delete(:install_path)
      install_path = resolve_install_path(install_path)
      validate_install_path(install_path, name)
    else
      install_path = @moduledir
    end

    if @default_branch_override != nil
      args[:default_branch_override] = @default_branch_override
    end


    mod = R10K::Module.new(name, install_path, args, @environment)
    mod.origin = :puppetfile

    # Do not load modules if they would conflict with the attached
    # environment
    if environment && environment.module_conflicts?(mod)
      mod = nil
      return @modules
    end

    # Keep track of all the content this Puppetfile is managing to enable purging.
    @managed_content[install_path] = Array.new unless @managed_content.has_key?(install_path)
    @managed_content[install_path] << mod.name

    @modules << mod
  end

  include R10K::Util::Purgeable

  def managed_directories
    self.load unless @loaded

    dirs = @managed_content.keys
    dirs.delete(real_basedir)
    dirs
  end

  # Returns an array of the full paths to all the content being managed.
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    self.load unless @loaded

    @managed_content.flat_map do |install_path, modnames|
      modnames.collect { |name| File.join(install_path, name) }
    end
  end

  def purge_exclusions
    exclusions = managed_directories

    if environment && environment.respond_to?(:desired_contents)
      exclusions += environment.desired_contents
    end

    exclusions
  end

  def accept(visitor)
    pool_size = self.settings[:pool_size]
    if pool_size > 1
      R10K::ContentSynchronizer.concurrent_accept(modules, visitor, self, pool_size, logger)
    else
      R10K::ContentSynchronizer.serial_accept(modules, visitor, self)
    end
  end

  def sync
    pool_size = self.settings[:pool_size]
    if pool_size > 1
      R10K::ContentSynchronizer.concurrent_sync(modules, pool_size, logger)
    else
      R10K::ContentSynchronizer.serial_sync(modules)
    end
  end

  private

  def puppetfile_contents
    File.read(@puppetfile_path)
  end

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
    unless /^#{Regexp.escape(real_basedir)}.*/ =~ path
      raise R10K::Error.new("Puppetfile cannot manage content '#{modname}' outside of containing environment: #{path} is not within #{real_basedir}")
    end

    true
  end

  def real_basedir
    Pathname.new(basedir).cleanpath.to_s
  end

  DSL = R10K::ModuleLoader::Puppetfile::DSL
end
end
