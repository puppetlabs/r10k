require 'puppet_forge'

class R10K::MockModule

  # @!attribute [r] title
  #   @return [String] The forward slash separated owner and name of the module
  attr_reader :title

  # @!attribute [r] name
  #   @return [String] The name of the module
  attr_reader :name

  # @param [r] dirname
  #   @return [String] The name of the directory containing this module
  attr_reader :dirname

  # @!attribute [r] owner
  #   @return [String, nil] The owner of the module if one is specified
  attr_reader :owner

  # @!attribute [r] path
  #   @return [Pathname] The full path of the module
  attr_reader :path

  # @!attribute [r] version
  #   @return [Pathname] The version, if it can be statically determined from args
  attr_reader :version

  # @param title [String]
  # @param dirname [String]
  # @param args [Array]
  def initialize(title, dirname, args, environment=nil)
    @title   = PuppetForge::V3.normalize_name(title)
    @dirname = dirname
    @owner, @name = parse_title(@title)
    @path = Pathname.new(File.join(@dirname, @name))
    @version = find_version(args)
  end

  private

  def find_version(args)
    if args.is_a?(String)
      args
    elsif args.is_a?(Hash)
      if args[:type] == 'forge'
        args[:version]
      elsif args[:ref] && args[:ref].match(/[0-9a-f]{40}/)
        args[:ref]
      elsif args[:type] == 'git' && args[:version].match(/[0-9a-f]{40}/)
        args[:version]
      else
        args[:tag] || args[:commit]
      end
    end
  end

  def parse_title(title)
    if (match = title.match(/\A(\w+)\Z/))
      [nil, match[1]]
    elsif (match = title.match(/\A(\w+)[-\/](\w+)\Z/))
      [match[1], match[2]]
    end
  end
end
