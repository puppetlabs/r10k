require 'r10k/formatter/base_formatter'

module R10K
  module Formatter
    class ClassicPuppetfile < BaseFormatter

      # @note The classic formatter is the "base" type for the puppetfile that most people will use.
      # The ClassicPuppetfile format is a Ruby format that utilizes a DSL to read the file and produce
      # the internal data structure that makes up the puppetfile.

      # @return [Array<String>] returns the original set of modules
      # stores all the content in librarian
      def load_content!
        dsl = DSL.new(self)
        dsl.instance_eval(puppetfile_contents, librarian_file_path)
        validate_no_duplicate_names(librarian.modules)
      rescue SyntaxError, LoadError, ArgumentError, NameError => e
        raise R10K::Error.wrap(e, _("Failed to evaluate %{path}") % {path: librarian_file_path})
      end

      def self.type_name
        'classic'
      end

      class DSL
        # A barebones implementation of the Puppetfile DSL
        #
        # @api private
        attr_reader :parent

        def initialize(parent)
          @parent = parent
        end

        def puppetfile_type(type)
          parent.set_puppetfile_type(type)
        end

        def mod(name, args = nil)
          parent.add_module(name, args)
        end

        def forge(location)
          parent.set_forge(location)
        end

        def moduledir(location)
          parent.set_moduledir(location)
        end

        def method_missing(method, *args)
          raise NoMethodError, _("unrecognized declaration '%{method}'") % {method: method}
        end
      end
    end

  end
end
