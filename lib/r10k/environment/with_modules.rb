require 'r10k/util/purgeable'

# This abstract base class implements an environment that can include module
# content
#
# @since 3.4.0
class R10K::Environment::WithModules < R10K::Environment::Base

  # @!attribute [r] moduledir
  #   @return [String] The directory to install environment-defined modules
  #     into (default: #{basedir}/modules)
  attr_reader :moduledir

  # Initialize the given environment.
  #
  # @param name [String] The unique name describing this environment.
  # @param basedir [String] The base directory where this environment will be created.
  # @param dirname [String] The directory name for this environment.
  # @param options [Hash] An additional set of options for this environment.
  #
  # @param options [String] :moduledir The path to install modules to
  # @param options [Hash] :modules Modules to add to the environment
  def initialize(name, basedir, dirname, options = {})
    super

    @managed_content = {}
    @modules = []
    @moduledir = case options[:moduledir]
                 when nil
                   File.join(@basedir, @dirname, 'modules')
                 when File.absolute_path(options[:moduledir])
                   options.delete(:moduledir)
                 else
                   File.join(@basedir, @dirname, options.delete(:moduledir))
                 end

    modhash = options.delete(:modules)
    load_modules(modhash) unless modhash.nil?
  end

  # @return [Array<R10K::Module::Base>] All modules associated with this environment.
  #   Modules may originate from either:
  #     - The r10k environment object
  #     - A Puppetfile in the environment's content
  def modules
    return @modules if puppetfile.nil?

    puppetfile.load unless puppetfile.loaded?
    @modules + puppetfile.modules
  end

  def module_conflicts?(mod_b)
    conflict = @modules.any? { |mod_a| mod_a.name == mod_b.name }
    return false unless conflict

    msg_vars = {src: mod_b.origin, name: mod_b.name}
    msg_error = _('Environment and %{src} both define the "%{name}" module' % msg_vars)
    msg_continue = _("#{msg_error}. The %{src} definition will be ignored" % msg_vars)

    case conflict_opt = @options[:module_conflicts]
    when 'override_and_warn', nil
      logger.warn msg_continue
    when 'override'
      logger.debug msg_continue
    when 'error'
      raise R10K::Error, msg_error
    else
      raise R10K::Error, _('Unexpected value for `module_conflicts` setting in %{env} ' \
                           'environment: %{val}' % {env: self.name, val: conflict_opt})
    end

    true
  end

  def accept(visitor)
    visitor.visit(:environment, self) do
      @modules.each do |mod|
        mod.sync
      end

      puppetfile.accept(visitor)
    end
  end

  def deploy
    @modules.each do |mod|
      mod.sync
    end

    super
  end

  def load_modules(module_hash)
    module_hash.each do |name, args|
      if !args.is_a?(Hash)
        args = { version: args }
      end

      add_module(name, args)
    end
  end

  # @param [String] name
  # @param [Hash] args
  def add_module(name, args)
    # symbolize keys in the args hash
    args = args.inject({}) { |memo,(k,v)| memo[k.to_sym] = v; memo }
    args[:overrides] = @overrides

    if install_path = args.delete(:install_path)
      install_path = resolve_install_path(install_path)
      validate_install_path(install_path, name)
    else
      install_path = @moduledir
    end

    # Keep track of all the content this environment is managing to enable purging.
    @managed_content[install_path] = Array.new unless @managed_content.has_key?(install_path)

    mod = R10K::Module.new(name, install_path, args, self.name)
    mod.origin = :environment

    @managed_content[install_path] << mod.name
    @modules << mod
  end

  include R10K::Util::Purgeable

  # Returns an array of the full paths that can be purged.
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def managed_directories
    [@full_path]
  end

  # Returns an array of the full paths of filenames that should exist. Files
  # inside managed_directories that are not listed in desired_contents will
  # be purged.
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    list = @managed_content.keys
    list += @managed_content.flat_map do |install_path, modnames|
      modnames.collect { |name| File.join(install_path, name) }
    end
  end

  def purge_exclusions
    super + @managed_content.flat_map do |install_path, modnames|
      modnames.map do |name|
        File.join(install_path, name, '**', '*')
      end
    end
  end
end
