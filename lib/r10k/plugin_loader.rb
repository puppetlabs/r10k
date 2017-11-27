require 'pathname'
require 'r10k/errors'
module R10K
  module PluginLoader

    def formatter_path
      File.join('lib','r10k','formatter')
    end

    def load_plugins
      load_from_gems
    end

    def excluded_classes
      [R10K::Formatter::BaseFormatter]
    end

    def included_lib_dirs
      [formatter_path]
    end

    # returns an array of plugin classes by looking in the object space for all loaded classes
    # that start with R10K::Formatter
    def plugin_classes
      unless @plugin_classes
        load_plugins
        # weed out any subclasses in the formatter
        @plugin_classes = ObjectSpace.each_object(Class).find_all { |c| c.name && c.name.split('::').count == 3 && c.name =~ /R10K::Formatter/ } - excluded_classes || []
      end
      @plugin_classes
    end

    def plugin_map
      @plugin_map ||= Hash[plugin_classes.map { |gem| [gem.send(:plugin_name) , gem] }]
    end

    def installed_plugins
      r10k_formatter_gem_list
    end

    # Internal: Find any gems containing r10k formatter plugins and load the main file in them.
    #
    # @return [Array[String]] - a array of formatter files
    def load_from_gems
      gem_directories.map do |gem_path|
        Dir[File.join(gem_path,'*.rb')].each do |file|
          load file
        end
      end.flatten
    end

    # Internal: Retrieve a list of available gem paths from RubyGems.
    #
    # Returns an Array of Pathname objects.
    def gem_directories
      dirs = []
      if has_rubygems?
       dirs = gemspecs.map do |spec|
          lib_path = File.expand_path(File.join(spec.full_gem_path,formatter_path))
          lib_path if File.exists? lib_path
        end + included_lib_dirs
      end
      dirs.reject { |dir| dir.nil? }.uniq
    end


    # returns a list of r10k formatter gem plugin specs
    def r10k_formatter_gem_list
      gemspecs.find_all { |spec| File.directory?(File.join(spec.full_gem_path,formatter_path)) } + included_lib_dirs
    end

    # Internal: Check if RubyGems is loaded and available.
    #
    # Returns true if RubyGems is available, false if not.
    def has_rubygems?
      defined? ::Gem
    end

    # Internal: Retrieve a list of available gemspecs.
    #
    # Returns an Array of Gem::Specification objects.
    def gemspecs
      @gemspecs ||= if Gem::Specification.respond_to?(:latest_specs)
                      Gem::Specification.latest_specs
                    else
                      Gem.searcher.init_gemspecs
                    end
    end

    # @return [Class] - the first formatter found that is compatible with the puppetfile
    def first_formatter(path)
      f = plugin_classes.find do | format |
        format.validate_formatter(path)
      end
      raise R10K::NoFormatterError.new("Cannot find a formatter for #{path}") unless f
      f
    end
  end
end