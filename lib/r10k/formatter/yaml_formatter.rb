require 'r10k/formatter/base_formatter'
require 'yaml'

module R10K
  module Formatter
    class YamlFormatter < BaseFormatter

      def load_content!
        load_yaml
        validate_no_duplicate_names(modules)
      end

      def self.type_name
        'yaml'
      end

      private

      def add_modules(modules)
        modules.each_with_object({}) do |m, args|
          if m.is_a?(Hash)
            name, data = m.first
            if data.is_a?(Hash)
              args = data
            elsif data != 'latest'
              args[:version] = data
            else
              args[:version] = :latest
            end
          else
            name = m
            args[:version] = :latest
          end
          add_module(name, args)
        end
      end

      def puppetfile_type(type)
        set_puppetfile_type(type)
      end

      def add_git_modules(gits)
        gits.each do |org_base, modules|
          modules.each do |m|
            if !(m.is_a?(Hash))
              m = { m => 'master' }
            end
            args = Hash.new
            repo, data = m.first
            if data.is_a?(Hash)
              args = data
            else
              name = repo.split('-', 2)[-1].gsub(/-/, '_')
              args[:git] = "#{org_base}/#{repo}.git"
              args[:ref] = data
            end
            add_module(name, args)
          end
        end
      end

      def load_yaml
        conf = YAML.safe_load(File.read(librarian_file_path))
        puppetfile_type(conf['puppetfile_type'])
        forge_conf = conf.fetch('forge', [""])
        forge, mods = forge_conf.first
        set_forge(forge)
        add_modules(mods) if mods
        add_git_modules(conf['git']) if conf['git']
        modules
      rescue SyntaxError, LoadError, ArgumentError => e
        raise R10K::Error.wrap(e, "Failed to evaluate #{@puppetfile_yaml_path}")
      end

    end
  end
end



