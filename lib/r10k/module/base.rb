require 'r10k/module'

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

  # There's been some churn over `author` vs `owner` and `full_name` over
  # `title`, so in the short run it's easier to support both and deprecate one
  # later.
  alias :author :owner
  alias :full_name :title

  # @param title [String]
  # @param dirname [String]
  # @param args [Array]
  def initialize(title, dirname, args)
    @title   = title
    @dirname = dirname
    @args    = args
    @owner, @name = parse_title(title)
    @path = Pathname.new(File.join(@dirname, @name))
  end

  # @deprecated
  # @return [String] The full filesystem path to the module.
  def full_path
    path.to_s
  end

  private

  def parse_title(title)
    if (match = title.match(/\A(\w+)\Z/))
      [nil, match[1]]
    elsif (match = title.match(/\A(\w+)[-\/](\w+)\Z/))
      [match[1], match[2]]
    else
      raise ArgumentError, "Module names must match either 'modulename' or 'owner/modulename'"
    end
  end
end
