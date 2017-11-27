require 'pathname'
require 'r10k/module'
require 'r10k/util/purgeable'
require 'r10k/errors'
require 'fileutils'

module R10K
  module Formatter
    class BaseFormatter

      include R10K::Logging

      # @!attrbute [r] librarian_file_path
      #   @return [String] The path to the Puppetfile
      attr_reader :librarian_file_path

      # @!attribute [r] modules
      #   @return [Array<R10K::Module>]
      attr_reader :modules

      attr_reader :librarian
      attr_reader :discovered_type

      def initialize(librarian_file_path, librarian)
        @librarian_file_path = librarian_file_path
        @librarian = librarian
      end

      # @return [Array] - the list of modules that was added to librarian
      def modules
        librarian.modules
      end

      # @return [Hash] - the module that was added
      # @param name [String] - the namespaced name of the module
      # @param args [Hash] - the module arguments, like repo, version, ref
      def add_module(name, args)
        librarian.add_module(name, args)
      end

      # @param location [String] - the path to the module directory
      def set_moduledir(location)
        librarian.set_moduledir(location)
      end

      # @param location [String] - the url to the forge
      def set_forge(location)
        librarian.set_forge(location)
      end

      # @param type [String] - the puppetfile formatter type that was found in the puppetfile
      def set_puppetfile_type(type)
        @discovered_type = type.to_s
      end

      # @return [String] - the formatter type name
      # If you are creating a new format you must implement this method
      def self.type_name
        raise NotImplemented
      end

      # @return [String] - the serialized output of the format
      # If you are creating a new format you must implement this method
      def to_s
        raise NotImplemented
      end

      # @return [Array<String>] returns the original set of modules
      def load_content
        if File.readable? librarian_file_path
          self.load_content!
        else
          logger.debug _("Puppetfile %{path} missing or unreadable") % {path: librarian_file_path.inspect}
        end
      end

      # @param file_path [String] - the file to save the content to
      # @return [String] - the file path that was used to save the file
      def export(file_path)
        FileUtils.mkdir_p(File.dirname(file_path)) unless File.dirname(file_path)
        File.write(file_path, to_s)
        to_s
      end

      # @return [Array<String>] returns the original set of modules
      # stores all the content in librarian
      def load_content!
        raise NotImplementedError
      end

      # @param [Array<String>] modules
      # @return [Array<String>] returns the original set of modules
      def validate_no_duplicate_names(modules)
        dupes = modules
                    .group_by { |mod| mod.name }
                    .select { |_, v| v.size > 1 }
                    .map(&:first)
        unless dupes.empty?
          msg = _('Puppetfiles cannot contain duplicate module names.')
          msg += ' '
          msg += _("Remove the duplicates of the following modules: %{dupes}" % { dupes: dupes.join(' ') })
          raise R10K::Error.new(msg)
        end
        modules
      end

      # @return [Boolean] - true if the pupetfile matches the type specified by the formatter
      # @param librarian_file_path [String] - the path to the puppetfile or whatever file it is named
      # this can be seen as a detection mechanism since we don't really know what kind of format the puppetfile will be in
      # This will only match if the user has supplied "puppetfile_type TYPE_NAME"
      # in the Puppetfile
      def self.validate_formatter(librarian_file_path)
        match = File.readlines(librarian_file_path).grep(/puppetfile_type/).first
        return false unless match
        match.chomp.split(' ').last.include?(self.type_name)
      end

      # @return [String] - the name of the formatter, ideally this should also be found in the associated librarian file
      def self.formatter_type
        raise NotImplementedError
      end

      private

      # @return [String] - the contents of the librarian file
      def puppetfile_contents
        File.read(librarian_file_path)
      end
    end
  end
end
