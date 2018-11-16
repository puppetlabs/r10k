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
  end

  # @deprecated
  # @return [String] The full filesystem path to the module.
  def full_path
    path.to_s
  end

  # Synchronize this module with the indicated state.
  # @abstract
  def sync(opts={})
    raise NotImplementedError
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
