require 'r10k/module/git'
require 'r10k/module/svn'
require 'r10k/module/forge'

module R10K
  module API
    class EnvmapBuilder
      def initialize
        @modules = []
      end

      def build
        @modules
      end

      # @param [String] forge
      def set_forge(forge)
        # No implementation for EnvMaps.
      end

      # @param [String] moduledir
      def set_moduledir(moduledir)
        # No implementation for EnvMaps.
      end

      # @param [String] name
      # @param [Hash] args
      def add_module(name, args)
        name_parts = name.split(/[\-\/]/, 2)
        mod_name = name_parts.size > 1 ? name_parts.last : name

        if @modules.collect { |m| m[:name] }.include?(mod_name)
          raise RuntimeError, "Puppetfile cannot declare the same module name twice: #{mod_name} was already declared"
        end

        case
        when R10K::Module::Git.implement?(name, args)
          git_opts = R10K::Module::Git.parse_options(args)
          module_data = { :type => :git, :source => git_opts[:remote], :version => git_opts[:ref] }
        when R10K::Module::SVN.implement?(name, args)
          module_data = { :type => :svn, :source => args[:url], :version => (args[:rev] || args[:revision] || "unpinnned") }
        when R10K::Module::Forge.implement?(name, args)
          module_data = { :type => :forge, :source => name_parts.join('-'), :version => (args || "unpinned") }
        when R10K::Module::Local.implement?(name, args)
          raise NotImplementedError
        else
          raise RuntimeError, "Unregonized module type in Puppetfile: #{name} #{args}"
        end

        @modules << { :name => mod_name }.merge(module_data)
      end
    end
  end
end
