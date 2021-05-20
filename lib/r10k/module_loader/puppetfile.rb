require 'r10k/logging'

module R10K
  module ModuleLoader
    class Puppetfile

      include R10K::Logging

      attr_accessor :default_branch_override, :environment
      attr_reader :modules, :moduledir,
        :managed_directories, :desired_contents, :purge_exclusions

      # @param [Hash] options
      # @option options [String] :puppetfile
      # @option options [String] :moduledir
      # @option options [String] :basedir
      # @option options [String] :forge
      # @option options [Hash] :overrides
      # @option options [R10K::Environment] :environment
      def initialize(puppetfile:, moduledir:, forge:, basedir:, overrides:, environment:)
        @puppetfile  = puppetfile
        @moduledir   = moduledir
        @basedir     = basedir
        @overrides   = overrides
        @environment = environment

        @modules = []
        @managed_content = {}

        @managed_directories = []
        @desired_contents = []
        @purge_exclusions = []
      end

      def load!
        if !File.readable?(@puppetfile)
          logger.debug _("Puppetfile %{path} missing or unreadable") % {path: @puppetfile.inspect}
          return false
        end

        dsl = R10K::ModuleLoader::Puppetfile::DSL.new(self)
        dsl.instance_eval(File.read(@puppetfile), @puppetfile)

        validate_no_duplicate_names(@modules)
        set_managed_directories
        set_desired_contents
        set_purge_exclusions

        {
          modules: @modules,
          managed_directories: @managed_directories,
          desired_contents: @desired_contents,
          purge_exclusions: @purge_exclusions
        }

      rescue SyntaxError, LoadError, ArgumentError, NameError => e
        raise R10K::Error.wrap(e, _("Failed to evaluate %{path}") % {path: @puppetfile})
      end

      # @param [String] forge
      def set_forge(forge)
        @forge = forge
      end

      # @param [String] moduledir
      def set_moduledir(moduledir)
        @moduledir = if Pathname.new(moduledir).absolute?
          moduledir
        else
          File.join(@basedir, moduledir)
        end
      end

      # @param [String] name
      # @param [Hash, String, Symbol] args Calling with anything but a Hash is
      #   deprecated. The DSL will now convert String and Symbol versions to
      #   Hashes of the shape
      #     { version: <String or Symbol> }
      #
      def add_module(name, args)
        if !args.is_a?(Hash)
          args = { version: args }
        end

        args[:overrides] = @overrides

        if install_path = args.delete(:install_path)
          install_path = resolve_install_path(install_path)
          validate_install_path(install_path, name)
        else
          install_path = @moduledir
        end

        if @default_branch_override != nil
          args[:default_branch_override] = @default_branch_override
        end

        mod = R10K::Module.new(name, install_path, args, @environment)
        mod.origin = :puppetfile

        # Do not load modules if they would conflict with the attached
        # environment
        if @environment && @environment.module_conflicts?(mod)
          mod = nil
          return @modules
        end

        # Keep track of all the content this Puppetfile is managing to enable purging.
        @managed_content[install_path] = Array.new unless @managed_content.has_key?(install_path)
        @managed_content[install_path] << mod.name

        @modules << mod
      end



     private
      # @param [Array<String>] modules
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
      end

      def resolve_install_path(path)
        pn = Pathname.new(path)

        unless pn.absolute?
          pn = Pathname.new(File.join(@basedir, path))
        end

        # .cleanpath is as good as we can do without touching the filesystem.
        # The .realpath methods will also choke if some of the intermediate
        # paths are missing, even though we will create them later as needed.
        pn.cleanpath.to_s
      end

      def validate_install_path(path, modname)
        unless /^#{Regexp.escape(real_basedir)}.*/ =~ path
          raise R10K::Error.new("Puppetfile cannot manage content '#{modname}' outside of containing environment: #{path} is not within #{real_basedir}")
        end

        true
      end

      def set_managed_directories
        @managed_directories = @managed_content.keys.reject { |dir| dir == real_basedir }
      end

      # Returns an array of the full paths to all the content being managed.
      # @return [Array<String>]
      def set_desired_contents
        @desired_contents = @managed_content.flat_map do |install_path, modnames|
          modnames.collect { |name| File.join(install_path, name) }
        end
      end

      def set_purge_exclusions
        exclusions = managed_directories

        if environment && environment.respond_to?(:desired_contents)
          exclusions += environment.desired_contents
        end

        @purge_exclusions = exclusions
      end

      def real_basedir
        Pathname.new(@basedir).cleanpath.to_s
      end

    end
  end
end
