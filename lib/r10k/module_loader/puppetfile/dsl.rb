module R10K
  module ModuleLoader
    class Puppetfile
      class DSL
        # A barebones implementation of the Puppetfile DSL
        #
        # @api private

        def initialize(librarian, metadata_only: false)
          @librarian     = librarian
          @metadata_only = metadata_only
        end

        def mod(name, args = nil)
          if args.is_a?(Hash)
            opts = args
          else
            opts = { version: args }
          end

          if @metadata_only
            @librarian.add_module_metadata(name, opts)
          else
            @librarian.add_module(name, opts)
          end
        end

        def forge(location)
          @librarian.set_forge(location)
        end

        def moduledir(location)
          @librarian.set_moduledir(location)
        end

        def method_missing(method, *args)
          raise NoMethodError, _("unrecognized declaration '%{method}'") % {method: method}
        end
      end
    end
  end
end
