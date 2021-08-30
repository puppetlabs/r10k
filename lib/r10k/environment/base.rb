require 'r10k/content_synchronizer'
require 'r10k/logging'
require 'r10k/module_loader/puppetfile'
require 'r10k/util/cleaner'
require 'r10k/util/subprocess'

# This class defines a common interface for environment implementations.
#
# @since 1.3.0
class R10K::Environment::Base

  include R10K::Logging

  # @!attribute [r] name
  #   @return [String] A name for this environment that is unique to the given source
  attr_reader :name

  # @!attribute [r] basedir
  #   @return [String] The path that this environment will be created in
  attr_reader :basedir

  # @!attribute [r] dirname
  #   @return [String] The directory name for the given environment
  attr_reader :dirname

  # @!attribute [r] path
  #   @return [Pathname] The full path to the given environment
  attr_reader :path

  # @!attribute [r] puppetfile
  #   @api public
  #   @return [R10K::Puppetfile] The puppetfile instance associated with this environment
  attr_reader :puppetfile

  # @!attribute [r] puppetfile_name
  #   @api public
  #   @return [String] The puppetfile name (relative)
  attr_reader :puppetfile_name

  attr_reader :managed_directories, :desired_contents

  attr_reader :loader

  # Initialize the given environment.
  #
  # @param name [String] The unique name describing this environment.
  # @param basedir [String] The base directory where this environment will be created.
  # @param dirname [String] The directory name for this environment.
  # @param options [Hash] An additional set of options for this environment.
  #   The semantics of this environment may depend on the environment implementation.
  def initialize(name, basedir, dirname, options = {})
    @name    = name
    @basedir = basedir
    @dirname = dirname
    @options = options
    @puppetfile_name = options.delete(:puppetfile_name)
    @overrides = options.delete(:overrides) || {}

    @full_path = File.join(@basedir, @dirname)
    @path = Pathname.new(File.join(@basedir, @dirname))

    @puppetfile  = R10K::Puppetfile.new(@full_path,
                                        {overrides: @overrides,
                                         force: @overrides.dig(:modules, :force),
                                         puppetfile_name: @puppetfile_name})
    @puppetfile.environment = self

    loader_options = { basedir: @full_path, overrides: @overrides, environment: self }
    loader_options[:puppetfile] = @puppetfile_name if @puppetfile_name

    @loader = R10K::ModuleLoader::Puppetfile.new(**loader_options)

    if @overrides.dig(:environments, :assume_unchanged)
      @loader.load_metadata
    end

    @base_modules = nil
    @purge_exclusions = nil
    @managed_directories = [ @full_path ]
    @desired_contents = []
  end

  # Synchronize the given environment.
  #
  # @api public
  # @abstract
  # @return [void]
  def sync
    raise NotImplementedError, _("%{class} has not implemented method %{method}") % {class: self.class, method: __method__}
  end

  # Determine the current status of the environment.
  #
  # This can return the following values:
  #
  #   * :absent - there is no module installed
  #   * :mismatched - there is a module installed but it must be removed and reinstalled
  #   * :outdated - the correct module is installed but it needs to be updated
  #   * :insync - the correct module is installed and up to date, or the module is actually a boy band.
  #
  # @api public
  # @abstract
  # @return [Symbol]
  def status
    raise NotImplementedError, _("%{class} has not implemented method %{method}") % {class: self.class, method: __method__}
  end

  # Returns a unique identifier for the environment's current state.
  #
  # @api public
  # @abstract
  # @return [String]
  def signature
    raise NotImplementedError, _("%{class} has not implemented method %{method}") %{class: self.class, method: __method__}
  end

  # Returns a hash describing the current state of the environment.
  #
  # @return [Hash]
  def info
    {
      :name => self.name,
      :signature => self.signature,
    }
  end

  # @return [Array<R10K::Module::Base>] All modules defined in the Puppetfile
  #   associated with this environment.
  def modules
    if @base_modules.nil?
      load_puppetfile_modules
    end

    @base_modules
  end

  # @return [Array<R10K::Module::Base>] Whether or not the given module
  #   conflicts with any modules already defined in the r10k environment
  #   object.
  def module_conflicts?(mod)
    false
  end

  def accept(visitor)
    visitor.visit(:environment, self) do
      puppetfile.accept(visitor)
    end
  end

  def deploy
    if @base_modules.nil?
      load_puppetfile_modules
    end

    if ! @base_modules.empty?
      pool_size = @overrides.dig(:modules, :pool_size)
      R10K::ContentSynchronizer.concurrent_sync(@base_modules, pool_size, logger)
    end

    if (@overrides.dig(:purging, :purge_levels) || []).include?(:puppetfile)
      logger.debug("Purging unmanaged Puppetfile content for environment '#{dirname}'...")
      @puppetfile_cleaner.purge!
    end
  end

  def load_puppetfile_modules
    loaded_content = @loader.load
    @base_modules = loaded_content[:modules]

    @purge_exclusions = determine_purge_exclusions(loaded_content[:managed_directories],
                                                   loaded_content[:desired_contents])

    @puppetfile_cleaner = R10K::Util::Cleaner.new(loaded_content[:managed_directories],
                                                  loaded_content[:desired_contents],
                                                  loaded_content[:purge_exclusions])
  end

  def whitelist(user_whitelist=[])
    user_whitelist.collect { |pattern| File.join(@full_path, pattern) }
  end

  def determine_purge_exclusions(pf_managed_dirs     = @puppetfile.managed_directories,
                                 pf_desired_contents = @puppetfile.desired_contents)

    list = [File.join(@full_path, '.r10k-deploy.json')].to_set

    list += pf_managed_dirs

    list += pf_desired_contents.flat_map do |item|
      desired_tree = []

      if File.directory?(item)
        desired_tree << File.join(item, '**', '*')
      end

      Pathname.new(item).ascend do |path|
        break if path.to_s == @full_path
        desired_tree << path.to_s
      end

      desired_tree
    end

    list.to_a
  end

  def purge_exclusions
    if @purge_exclusions.nil?
      load_puppetfile_modules
    end

    @purge_exclusions
  end

  def generate_types!
    argv = [R10K::Settings.puppet_path, 'generate', 'types', '--environment', dirname, '--environmentpath', basedir, '--config', R10K::Settings.puppet_conf]
    subproc = R10K::Util::Subprocess.new(argv)
    subproc.raise_on_fail = true
    subproc.logger = logger
    result = subproc.execute
    unless result.stderr.empty?
      logger.warn "There were problems generating types for environment #{dirname}:"
      result.stderr.split(%r{\n}).map { |msg| logger.warn msg }
    end
  end
end
