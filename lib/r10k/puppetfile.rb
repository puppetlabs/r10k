require 'thread'
require 'pathname'
require 'r10k/module'
require 'r10k/util/purgeable'
require 'r10k/errors'
require 'r10k/content_synchronizer'
require 'r10k/module_loader/puppetfile/dsl'
require 'r10k/module_loader/puppetfile'

module R10K

# Deprecated, use R10K::ModuleLoader::Puppetfile#load to load content,
# provide the `:modules` key of the returned Hash to
# R10K::ContentSynchronizer (either the `serial_sync` or `concurrent_sync`)
# and the remaining keys (`:managed_directories`, `:desired_contents`, and
# `:purge_exclusions`) to R10K::Util::Cleaner.
class Puppetfile

  include R10K::Settings::Mixin

  def_setting_attr :pool_size, 4

  include R10K::Logging

  # @!attribute [r] forge
  #   @return [String] The URL to use for the Puppet Forge
  attr_reader :forge

  # @!attribute [r] basedir
  #   @return [String] The base directory that contains the Puppetfile
  attr_reader :basedir

  # @!attribute [r] environment
  #   @return [R10K::Environment] Optional R10K::Environment that this Puppetfile belongs to.
  attr_reader :environment

  # @!attribute [rw] force
  #   @return [Boolean] Overwrite any locally made changes
  attr_accessor :force

  # @!attribute [r] overrides
  #   @return [Hash] Various settings overridden from normal configs
  attr_reader :overrides

  # @!attribute [r] loader
  #   @return [R10K::ModuleLoader::Puppetfile] The internal module loader
  attr_reader :loader

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
    puppetfile_name = deprecated_name_arg      || options.delete(:puppetfile_name) || 'Puppetfile'
    puppetfile_path = deprecated_path_arg      || options.delete(:puppetfile_path)
    @puppetfile = puppetfile_path || puppetfile_name
    @environment     = options.delete(:environment)

    @overrides       = options.delete(:overrides) || {}
    @default_branch_override = @overrides.dig(:environments, :default_branch_override)

    @forge   = 'forgeapi.puppetlabs.com'

    @loader = ::R10K::ModuleLoader::Puppetfile.new(
      basedir: @basedir,
      moduledir: @moduledir,
      puppetfile: @puppetfile,
      overrides: @overrides,
      environment: @environment
    )

    @loaded_content = {
      modules: [],
      managed_directories: [],
      desired_contents: [],
      purge_exclusions: []
    }

    @loaded = false
  end

  # @param [String] default_branch_override The default branch to use
  #   instead of one specified in the module declaration, if applicable.
  #   Deprecated, use R10K::ModuleLoader::Puppetfile directly and pass
  #   the default_branch_override as an option on initialization.
  def load(default_branch_override = nil)
    if self.loaded?
      return @loaded_content
    else
      if !File.readable?(puppetfile_path)
        logger.debug _("Puppetfile %{path} missing or unreadable") % {path: puppetfile_path.inspect}
      else
        self.load!(default_branch_override)
      end
    end
  end

  # @param [String] default_branch_override The default branch to use
  #   instead of one specified in the module declaration, if applicable.
  #   Deprecated, use R10K::ModuleLoader::Puppetfile directly and pass
  #   the default_branch_override as an option on initialization.
  def load!(default_branch_override = nil)

    if default_branch_override && (default_branch_override != @default_branch_override)
      logger.warn("Mismatch between passed and initialized default branch overrides, preferring passed value.")
      @loader.default_branch_override = default_branch_override
    end

    @loaded_content = @loader.load!
    @loaded = true

    @loaded_content
  end

  def loaded?
    @loaded
  end

  def modules
    @loaded_content[:modules]
  end

  # @see R10K::ModuleLoader::Puppetfile#add_module for upcoming signature changes
  def add_module(name, args)
    @loader.add_module(name, args)
  end

  def set_moduledir(dir)
    @loader.set_moduledir(dir)
  end

  def set_forge(forge)
    @loader.set_forge(forge)
  end

  def moduledir
    @loader.moduledir
  end

  def puppetfile_path
    @loader.puppetfile_path
  end

  def environment=(env)
    @loader.environment = env
    @environment = env
  end

  include R10K::Util::Purgeable

  def managed_directories
    self.load

    @loaded_content[:managed_directories]
  end

  # Returns an array of the full paths to all the content being managed.
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    self.load

    @loaded_content[:desired_contents]
  end

  def purge_exclusions
    self.load

    @loaded_content[:purge_exclusions]
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

  def real_basedir
    Pathname.new(basedir).cleanpath.to_s
  end

  DSL = R10K::ModuleLoader::Puppetfile::DSL
end
end
