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
      # @param puppetfile [String] The full path to the Puppetfile
      # @param moduledir [String] The full path to the moduledir
      # @param forge [String] The url (without protocol) to the Forge
      # @param overrides [Hash] Configuration for loaded modules' behavior
      # @param environment [R10K::Environment] The environment loading may be
      #     taking place within
      def initialize(basedir:,
                     moduledir: File.join(basedir, DEFAULT_MODULEDIR),
                     puppetfile: File.join(basedir, DEFAULT_PUPPETFILE_NAME),
                     forge: DEFAULT_FORGE_API,
                     overrides: {},
                     environment: nil)

        @basedir     = basedir
        @moduledir   = moduledir
        @puppetfile  = puppetfile
        @forge       = forge
        @overrides   = overrides
        @environment = environment

        @modules = []

        @managed_directories = []
        @desired_contents = []
        @purge_exclusions = []
      end

      def load!
        dsl = R10K::ModuleLoader::Puppetfile::DSL.new(self)
        dsl.instance_eval(puppetfile_content(@puppetfile), @puppetfile)

        validate_no_duplicate_names!(@modules)
        @modules.freeze

        managed_content = @modules.group_by(&:dirname).freeze

        @managed_directories = determine_managed_directories(managed_content).freeze
        @desired_contents = determine_desired_contents(managed_content).freeze
        @purge_exclusions = determine_purge_exclusions(@managed_directories.clone).freeze

        {
          modules: @modules,
          managed_directories: @managed_directories,
          desired_contents: @desired_contents,
          purge_exclusions: @purge_exclusions
        }.freeze

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
          validate_install_path!(install_path, name)
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

        @modules << mod
      end

     private

      # @param [Array<R10K::Module>] modules
      def validate_no_duplicate_names!(modules)
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

      def validate_install_path!(path, modname)
        unless /^#{Regexp.escape(real_basedir)}.*/ =~ path
          raise R10K::Error.new("Puppetfile cannot manage content '#{modname}' outside of containing environment: #{path} is not within #{real_basedir}")
        end

        true
      end

      def determine_managed_directories(managed_content)
        managed_content.keys.reject { |dir| dir == real_basedir }
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

      def real_basedir
        Pathname.new(@basedir).cleanpath.to_s
      end

      # For testing purposes only
      def puppetfile_content(path)
        File.read(path)
      end
    end
  end
end
