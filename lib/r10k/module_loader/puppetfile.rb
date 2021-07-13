module R10K
  module ModuleLoader
    class Puppetfile

      DEFAULT_MODULEDIR = 'modules'
      DEFAULT_PUPPETFILE_NAME = 'Puppetfile'
      DEFAULT_FORGE_API = 'forgeapi.puppetlabs.com'

      attr_accessor :default_branch_override, :environment
      attr_reader :modules, :moduledir,
        :managed_directories, :desired_contents, :purge_exclusions

      # @param basedir [String] The path that contains the moduledir &
      #     Puppetfile by default. May be an environment, project, or
      #     simple directory.
      # @param puppetfile [String] The path to the Puppetfile, either an
      #     absolute full path or a relative path with regards to the basedir.
      # @param moduledir [String] The path to the moduledir, either an
      #     absolute full path or a relative path with regards to the basedir.
      # @param forge [String] The url (without protocol) to the Forge
      # @param overrides [Hash] Configuration for loaded modules' behavior
      # @param environment [R10K::Environment] When provided, the environment
      #     in which loading takes place
      def initialize(basedir:,
                     moduledir: DEFAULT_MODULEDIR,
                     puppetfile: DEFAULT_PUPPETFILE_NAME,
                     forge: DEFAULT_FORGE_API,
                     overrides: {},
                     environment: nil)

        @basedir     = cleanpath(basedir)
        @moduledir   = resolve_path(@basedir, moduledir)
        @puppetfile  = resolve_path(@basedir, puppetfile)
        @forge       = forge
        @overrides   = overrides
        @environment = environment
        @default_branch_override = @overrides.dig(:environments, :default_branch_override)

        @modules = []

        @managed_directories = []
        @desired_contents = []
        @purge_exclusions = []
      end

      def load
        dsl = R10K::ModuleLoader::Puppetfile::DSL.new(self)
        dsl.instance_eval(puppetfile_content(@puppetfile), @puppetfile)

        validate_no_duplicate_names(@modules)
        @modules

        managed_content = @modules.group_by(&:dirname)

        @managed_directories = determine_managed_directories(managed_content)
        @desired_contents = determine_desired_contents(managed_content)
        @purge_exclusions = determine_purge_exclusions(@managed_directories)

        {
          modules: @modules,
          managed_directories: @managed_directories,
          desired_contents: @desired_contents,
          purge_exclusions: @purge_exclusions
        }

      rescue SyntaxError, LoadError, ArgumentError, NameError => e
        raise R10K::Error.wrap(e, _("Failed to evaluate %{path}") % {path: @puppetfile})
      end


      ##
      ## set_forge, set_moduledir, and add_module are used directly by the DSL class
      ##

      # @param [String] forge
      def set_forge(forge)
        @forge = forge
      end

      # @param [String] moduledir
      def set_moduledir(moduledir)
        @moduledir = resolve_path(@basedir, moduledir)
      end

      # @param [String] name
      # @param [Hash, String, Symbol, nil] module_info Calling with
      #   anything but a Hash is deprecated. The DSL will now convert
      #   String and Symbol versions to Hashes of the shape
      #     { version: <String or Symbol> }
      #
      #   String inputs should be valid module versions, the Symbol
      #   `:latest` is allowed, as well as `nil`.
      #
      #   Non-Hash inputs are only ever used by Forge modules. In
      #   future versions this method will require the caller (the
      #   DSL class, not the Puppetfile author) to do this conversion
      #   itself.
      #
      def add_module(name, module_info)
        if !module_info.is_a?(Hash)
          module_info = { version: module_info }
        end

        module_info[:overrides] = @overrides

        if install_path = module_info.delete(:install_path)
          install_path = resolve_path(@basedir, install_path)
          validate_install_path(install_path, name)
        else
          install_path = @moduledir
        end

        if @default_branch_override
          module_info[:default_branch_override] = @default_branch_override
        end

        mod = R10K::Module.new(name, install_path, module_info, @environment)
        mod.origin = :puppetfile

        # Do not save modules if they would conflict with the attached
        # environment
        if @environment && @environment.module_conflicts?(mod)
          return @modules
        end

        @modules << mod
      end

     private

      # @param [Array<R10K::Module>] modules
      def validate_no_duplicate_names(modules)
        dupes = modules
                .group_by { |mod| mod.name }
                .select { |_, mods| mods.size > 1 }
                .map(&:first)
        unless dupes.empty?
          msg = _('Puppetfiles cannot contain duplicate module names.')
          msg += ' '
          msg += _("Remove the duplicates of the following modules: %{dupes}" % { dupes: dupes.join(' ') })
          raise R10K::Error.new(msg)
        end
      end

      def resolve_path(base, path)
        if Pathname.new(path).absolute?
          cleanpath(path)
        else
          cleanpath(File.join(base, path))
        end
      end

      def validate_install_path(path, modname)
        unless /^#{Regexp.escape(@basedir)}.*/ =~ path
          raise R10K::Error.new("Puppetfile cannot manage content '#{modname}' outside of containing environment: #{path} is not within #{@basedir}")
        end

        true
      end

      def determine_managed_directories(managed_content)
        managed_content.keys.reject { |dir| dir == @basedir }
      end

      # Returns an array of the full paths to all the content being managed.
      # @return [Array<String>]
      def determine_desired_contents(managed_content)
        managed_content.flat_map do |install_path, mods|
          mods.collect { |mod| File.join(install_path, mod.name) }
        end
      end

      def determine_purge_exclusions(managed_dirs)
        if environment && environment.respond_to?(:desired_contents)
          managed_dirs + environment.desired_contents
        else
          managed_dirs
        end
      end

      # .cleanpath is as close to a canonical path as we can do without touching
      # the filesystem. The .realpath methods will choke if some of the
      # intermediate paths are missing, even though in some cases we will create
      # them later as needed.
      def cleanpath(path)
        Pathname.new(path).cleanpath.to_s
      end

      # For testing purposes only
      def puppetfile_content(path)
        File.read(path)
      end
    end
  end
end
