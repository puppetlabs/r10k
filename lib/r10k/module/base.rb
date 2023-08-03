require 'r10k/module'
require 'r10k/logging'
require 'puppet_forge'

# This class defines a common interface for module implementations.
class R10K::Module::Base

  include R10K::Logging

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

  # @!attribute [rw] extra_delete
  #   @return [List[String]] set this to non-empty array of strings of files to remove from module after sync
  attr_accessor :extra_delete

  # There's been some churn over `author` vs `owner` and `full_name` over
  # `title`, so in the short run it's easier to support both and deprecate one
  # later.
  alias :author :owner
  alias :full_name :title

  # @param title [String]
  # @param dirname [String]
  # @param args [Hash]
  def initialize(title, dirname, args, environment=nil)
    @title   = PuppetForge::V3.normalize_name(title)
    @dirname = dirname
    @args    = args
    @owner, @name = parse_title(@title)
    @path = Pathname.new(File.join(@dirname, @name))
    @environment = environment
    @overrides = args.delete(:overrides) || {}
    @spec_deletable = true
    @exclude_spec = true
    @exclude_spec = @overrides.dig(:modules, :exclude_spec) unless @overrides.dig(:modules, :exclude_spec).nil?
    if args.has_key?(:exclude_spec)
      logger.debug2 _("Overriding :exclude_spec setting with per module setting for #{@title}")
      @exclude_spec = args.delete(:exclude_spec)
    end
    @extra_delete = []
    @extra_delete = @overrides.dig(:modules, :extra_delete) if @overrides.dig(:modules, :extra_delete)
    if args.has_key?(:extra_delete)
      logger.debug2 _("Overriding :extra_delete setting with per module setting for #{@title}")
      @extra_delete = args.delete(:extra_delete)
    end
    @origin = 'external' # Expect Puppetfile or R10k::Environment to set this to a specific value

    @requested_modules = @overrides.dig(:modules, :requested_modules) || []
    @should_sync = (@requested_modules.empty? || @requested_modules.include?(@name))
  end

  # @deprecated
  # @return [String] The full filesystem path to the module.
  def full_path
    path.to_s
  end

  # Delete the spec dir if @exclude_spec is true and @spec_deletable is also true
  def maybe_delete_spec_dir
    if @exclude_spec
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

  def maybe_extra_delete
    unless @extra_delete.empty?
        logger.info _("extra_delete for #{@title} enabled")
        extra_delete_rm
    end
  end

  def extra_delete_rm
    @extra_delete.each do | to_delete |

      to_delete_path = @path + to_delete
      # Is this safe? What is the symlink is outside our path?
      if to_delete_path.symlink?
        to_delete_path = to_delete_path.realpath
      end

      to_delete_path_glob = Dir.glob(to_delete_path) # returns a list

      to_delete_path_glob.each do | to_delete_path_i |
        if File.directory?(to_delete_path_i)
          logger.debug2 _("Deleting directory per extra_delete at #{to_delete_path_i}")
          # Use the secure flag for the #rm_rf, see full notes in delete_spec_dir function
          FileUtils.rm_rf(to_delete_path_i, secure: true)
        else
          logger.debug2 _("Deleting files per extra_delete at #{to_delete_path_i}")
          # Use rm, not rm_rf or rm_r. Directories should be covered above
          FileUtils.rm(to_delete_path_i)
        end
      end
    end
  end

  # Synchronize this module with the indicated state.
  # @param [Hash] opts Deprecated
  # @return [Boolean] true if the module was updated, false otherwise
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
