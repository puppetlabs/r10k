require 'r10k/errors'
require 'r10k/logging'
require 'r10k/module'
require 'r10k/module_loader/puppetfile/dsl'

require 'pathname'

module R10K
  module ModuleLoader
    class Puppetfile

      include R10K::Logging

      DEFAULT_MODULEDIR = 'modules'
      DEFAULT_PUPPETFILE_NAME = 'Puppetfile'

      attr_accessor :default_branch_override, :environment
      attr_reader :modules, :moduledir, :puppetfile_path,
        :managed_directories, :desired_contents, :purge_exclusions,
        :environment_name

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
                     overrides: {},
                     environment: nil)

        @basedir     = cleanpath(basedir)
        @moduledir   = resolve_path(@basedir, moduledir)
        @puppetfile_path  = resolve_path(@basedir, puppetfile)
        @overrides   = overrides
        @environment = environment
        @environment_name = @environment&.name
        @default_branch_override = @overrides.dig(:environments, :default_branch_override)
        @allow_puppetfile_forge = @overrides.dig(:forge, :allow_puppetfile_override)

        @existing_module_metadata = []
        @existing_module_versions_by_name = {}
        @modules = []

        @managed_directories = []
        @desired_contents = []
        @purge_exclusions = []
      end

      def load
        with_readable_puppetfile(@puppetfile_path) do
          self.load!
        end
      end

      def load!
        logger.info _("Using Puppetfile '%{puppetfile}'") % {puppetfile: @puppetfile_path}
        logger.debug _("Using moduledir '%{moduledir}'") % {moduledir: @moduledir}

        dsl = R10K::ModuleLoader::Puppetfile::DSL.new(self)
        dsl.instance_eval(puppetfile_content(@puppetfile_path), @puppetfile_path)

        validate_no_duplicate_names(@modules)

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
        raise R10K::Error.wrap(e, _("Failed to evaluate %{path}") % {path: @puppetfile_path})
      end

      def load_metadata
        with_readable_puppetfile(@puppetfile_path) do
          self.load_metadata!
        end
      end

      def load_metadata!
        dsl = R10K::ModuleLoader::Puppetfile::DSL.new(self, metadata_only: true)
        dsl.instance_eval(puppetfile_content(@puppetfile_path), @puppetfile_path)

        @existing_module_versions_by_name = @existing_module_metadata.map {|mod| [ mod.name, mod.version ] }.to_h
        empty_load_output.merge(modules: @existing_module_metadata)

      rescue SyntaxError, LoadError, ArgumentError, NameError => e
        logger.warn _("Unable to preload Puppetfile because of %{msg}" % { msg: e.message })
      end

      def add_module_metadata(name, info)
        install_path, metadata_info, _ = parse_module_definition(name, info)

        mod = R10K::Module.from_metadata(name, install_path, metadata_info, @environment)

        @existing_module_metadata << mod
      end

      ##
      ## set_forge, set_moduledir, and add_module are used directly by the DSL class
      ##

      # @param [String] forge
      def set_forge(forge)
        if @allow_puppetfile_forge
          logger.debug _("Using Forge from Puppetfile: %{forge}") % { forge: forge }
          PuppetForge.host = forge
        else
          logger.debug _("Ignoring Forge declaration in Puppetfile, using value from settings: %{forge}.") % { forge: PuppetForge.host }
        end
      end

      # @param [String] moduledir
      def set_moduledir(moduledir)
        @moduledir = resolve_path(@basedir, moduledir)
      end

      # @param [String] name
      # @param [Hash, String, Symbol, nil] info Calling with
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
      def add_module(name, info)
        install_path, metadata_info, spec_deletable = parse_module_definition(name, info)

        mod = R10K::Module.from_metadata(name, install_path, metadata_info, @environment)
        mod.origin = :puppetfile
        mod.spec_deletable = spec_deletable

        # Do not save modules if they would conflict with the attached
        # environment
        if @environment && @environment.module_conflicts?(mod)
          return @modules
        end

        # If this module's metadata has a static version and that version
        # matches the existing module declaration use it, otherwise create
        # a regular module to sync.
        unless mod.version && (mod.version == @existing_module_versions_by_name[mod.name])
          mod = mod.to_implementation
        end

        @modules << mod
      end

     private

      def empty_load_output
        {
          modules: [],
          managed_directories: [],
          desired_contents: [],
          purge_exclusions: []
        }
      end

      def with_readable_puppetfile(puppetfile_path, &block)
        if File.readable?(puppetfile_path)
          block.call
        else
          logger.debug _("Puppetfile %{path} missing or unreadable") % {path: puppetfile_path.inspect}

          empty_load_output
        end
      end

      def parse_module_definition(name, info)
        if !info.is_a?(Hash)
          info = { version: info }
        end

        info[:overrides] = @overrides

        if @default_branch_override
          info[:default_branch_override] = @default_branch_override
        end

        spec_deletable = false
        if install_path = info.delete(:install_path)
          install_path = resolve_path(@basedir, install_path)
          validate_install_path(install_path, name)
        else
          install_path = @moduledir
          spec_deletable = true
        end

        return [ install_path, info, spec_deletable ]
      end

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
