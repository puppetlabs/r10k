require 'r10k/module'
require 'puppet_forge'

# This class defines a common interface for module implementations.
class R10K::Module::Base

  # @!attribute [r] title
  #   @return [String] The forward slash separated owner and name of the module
  attr_reader :title

  # @!attribute [r] name
  #   @return [String] The name of the module
  attr_reader :name

  # @param [r] dirname
  #   @return [String] The name of the directory containing this module
  attr_reader :dirname

  # @deprecated
  alias :basedir :dirname

  # @!attribute [r] owner
  #   @return [String, nil] The owner of the module if one is specified
  attr_reader :owner

  # @!attribute [r] path
  #   @return [Pathname] The full path of the module
  attr_reader :path

  # @!attribute [r] environment
  #   @return [R10K::Environment, nil] The parent environment of the module
  attr_reader :environment

  # @!attribute [rw] origin
  #   @return [String] Where the module was sourced from. E.g., "Puppetfile"
  attr_accessor :origin

  # @!attribute [rw] spec_deletable
  #   @return [Boolean] set this to true if the spec dir can be safely removed, ie in the moduledir
  attr_accessor :spec_deletable

  # There's been some churn over `author` vs `owner` and `full_name` over
  # `title`, so in the short run it's easier to support both and deprecate one
  # later.
  alias :author :owner
  alias :full_name :title

  # @param title [String]
  # @param dirname [String]
  # @param args [Array]
  def initialize(title, dirname, args, environment=nil)
    @title   = PuppetForge::V3.normalize_name(title)
    @dirname = dirname
    @args    = args
    @owner, @name = parse_title(@title)
    @path = Pathname.new(File.join(@dirname, @name))
    @environment = environment
    @overrides = args.delete(:overrides) || {}
    @spec_deletable = true
    @deploy_spec = args.delete(:deploy_spec)
    @deploy_spec = @overrides[:modules].delete(:deploy_spec) if @overrides.dig(:modules, :deploy_spec)
    @origin = 'external' # Expect Puppetfile or R10k::Environment to set this to a specific value

    @requested_modules = @overrides.dig(:modules, :requested_modules) || []
    @should_sync = (@requested_modules.empty? || @requested_modules.include?(@name))
  end

  # @deprecated
  # @return [String] The full filesystem path to the module.
  def full_path
    path.to_s
  end

  # Delete the spec dir unless @deploy_spec has been set to true or @spec_deletable is false
  def maybe_delete_spec_dir
    unless @deploy_spec
      if @spec_deletable
        delete_spec_dir
      else
        logger.info _("Spec dir for #{@title} will not be deleted because it is not in the moduledir")
      end
    end
  end

  # Actually remove the spec dir
  def delete_spec_dir
    spec_path = @path + 'spec'
    if spec_path.symlink?
      spec_path = spec_path.realpath
    end
    if spec_path.directory?
      logger.debug2 _("Deleting spec data at #{spec_path}")
      # Use the secure flag for the #rm_rf method to avoid security issues
      # involving TOCTTOU(time of check to time of use); more details here:
      # https://ruby-doc.org/stdlib-2.7.0/libdoc/fileutils/rdoc/FileUtils.html#method-c-rm_rf
      # Additionally, #rm_rf also has problems in windows with with symlink targets
      # also being deleted; this should be revisted if Windows becomes higher priority.
      FileUtils.rm_rf(spec_path, secure: true)
    else
      logger.debug2 _("No spec dir detected at #{spec_path}, skipping deletion")
    end
  end

  # Synchronize this module with the indicated state.
  # @param [Hash] opts Deprecated
  def sync(opts={})
    raise NotImplementedError
  end

  def should_sync?
    if @should_sync
      logger.info _("Deploying module to %{path}") % {path: path}
      true
    else
      logger.debug1(_("Only updating modules %{modules}, skipping module %{name}") % {modules: @requested_modules.inspect, name: name})
      false
    end
  end


  # Return the desired version of this module
  # @abstract
  def version
    raise NotImplementedError
  end

  # Return the status of the currently installed module.
  #
  # This can return the following values:
  #
  #   * :absent - there is no module installed
  #   * :mismatched - there is a module installed but it must be removed and reinstalled
  #   * :outdated - the correct module is installed but it needs to be updated
  #   * :insync - the correct module is installed and up to date, or the module is actually a boy band.
  #
  # @return [Symbol]
  # @abstract
  def status
    raise NotImplementedError
  end

  # Deprecated
  def accept(visitor)
    visitor.visit(:module, self)
  end

  # Return the properties of the module
  #
  # @return [Hash]
  # @abstract
  def properties
    raise NotImplementedError
  end

  # Return the module's cachedir. Subclasses that implement a cache
  # will override this to return a real directory location.
  #
  # @return [String, :none]
  def cachedir
    :none
  end

  private

  def parse_title(title)
    if (match = title.match(/\A(\w+)\Z/))
      [nil, match[1]]
    elsif (match = title.match(/\A(\w+)[-\/](\w+)\Z/))
      [match[1], match[2]]
    else
      raise ArgumentError, _("Module name (%{title}) must match either 'modulename' or 'owner/modulename'") % {title: title}
    end
  end
end
