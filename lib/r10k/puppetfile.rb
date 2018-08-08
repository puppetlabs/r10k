require 'pathname'
require 'r10k/module'
require 'r10k/util/purgeable'
require 'r10k/errors'

module R10K
class Puppetfile
  # Defines the data members of a Puppetfile

  include R10K::Logging

  # @!attribute [r] forge
  #   @return [String] The URL to use for the Puppet Forge
  attr_reader :forge

  # @!attribute [r] modules
  #   @return [Array<R10K::Module>]
  attr_reader :modules

  # @!attribute [r] basedir
  #   @return [String] The base directory that contains the Puppetfile
  attr_reader :basedir

  # @!attribute [r] moduledir
  #   @return [String] The directory to install the modules #{basedir}/modules
  attr_reader :moduledir

  # @!attrbute [r] puppetfile_path
  #   @return [String] The path to the Puppetfile
  attr_reader :puppetfile_path

  # @!attribute [rw] environment
  #   @return [R10K::Environment] Optional R10K::Environment that this Puppetfile belongs to.
  attr_accessor :environment

  # @!attribute [rw] force
  #   @return [Boolean] Overwrite any locally made changes
  attr_accessor :force

  # @param [String] basedir
  # @param [String] moduledir The directory to install the modules, default to #{basedir}/modules
  # @param [String] puppetfile_path The path to the Puppetfile, default to #{basedir}/Puppetfile
  # @param [String] puppetfile_name The name of the Puppetfile, default to 'Puppetfile'
  # @param [Boolean] force Shall we overwrite locally made changes?
  def initialize(basedir, moduledir = nil, puppetfile_path = nil, puppetfile_name = nil, force = nil )
    @basedir         = basedir
    @force           = force || false
    @moduledir       = moduledir  || File.join(basedir, 'modules')
    @puppetfile_path = puppetfile_path || File.join(basedir, 'Puppetfile')

    @modules = []
    @managed_content = {}
    @forge   = 'forgeapi.puppetlabs.com'

    @loaded = false
  end

  def load
    if File.readable? @puppetfile_path
      self.load!
    else
      logger.debug _("%{dirname}: Puppetfile %{path} missing or unreadable") % {dirname: dirname, path: @puppetfile_path.inspect}
    end
  end

  def load!
    dsl = R10K::Puppetfile::DSL.new(self)
    dsl.instance_eval(puppetfile_contents, @puppetfile_path)
    validate_no_duplicate_names(@modules)
    @loaded = true
  rescue SyntaxError, LoadError, ArgumentError => e
    raise R10K::Error.wrap(e, _("%{dirname}: Failed to evaluate %{path}") % {dirname: dirname, path: @puppetfile_path})
  end

  # @param [String] forge
  def set_forge(forge)
    @forge = forge
  end

  # @param [Array<String>] modules
  def validate_no_duplicate_names(modules)
    dupes = modules
            .group_by { |mod| mod.name }
            .select { |_, v| v.size > 1 }.map(&:first)
    unless dupes.empty?
      logger.warn _("%{dirname}: Puppetfiles should not contain duplicate module names and will result in an error in r10k v3.x." % {dirname: dirname})
      logger.warn _("%{dirname}: Remove the duplicates of the following modules: %{dupes}" % {dirname: dirname, dupes: dupes.join(" ")})
    end
  end

  # @param [String] moduledir
  def set_moduledir(moduledir)
    @moduledir = if Pathname.new(moduledir).absolute?
      moduledir
    else
      File.join(basedir, moduledir)
    end
  end

  # @param [String] name
  # @param [*Object] args
  def add_module(name, args)
    if args.is_a?(Hash) && install_path = args.delete(:install_path)
      install_path = resolve_install_path(install_path)
      validate_install_path(install_path, name)
    else
      install_path = @moduledir
    end

    # Keep track of all the content this Puppetfile is managing to enable purging.
    @managed_content[install_path] = Array.new unless @managed_content.has_key?(install_path)

    mod = R10K::Module.new(name, install_path, args, @environment)

    @managed_content[install_path] << mod.name
    @modules << mod
  end

  include R10K::Util::Purgeable

  def managed_directories
    self.load unless @loaded

    @managed_content.keys
  end

  # Returns an array of the full paths to all the content being managed.
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    self.load unless @loaded

    @managed_content.flat_map do |install_path, modnames|
      modnames.collect { |name| File.join(install_path, name) }
    end
  end

  def purge_exclusions
    exclusions = managed_directories

    if environment && environment.respond_to?(:desired_contents)
      exclusions += environment.desired_contents
    end

    exclusions
  end

  def accept(visitor)
    visitor.visit(:puppetfile, self) do
      modules.each do |mod|
        mod.accept(visitor)
      end
    end
  end

  private

  def puppetfile_contents
    File.read(@puppetfile_path)
  end

  def resolve_install_path(path)
    pn = Pathname.new(path)

    unless pn.absolute?
      pn = Pathname.new(File.join(basedir, path))
    end

    # .cleanpath is as good as we can do without touching the filesystem.
    # The .realpath methods will also choke if some of the intermediate
    # paths are missing, even though we will create them later as needed.
    pn.cleanpath.to_s
  end

  def validate_install_path(path, modname)
    real_basedir = Pathname.new(basedir).cleanpath.to_s

    unless /^#{Regexp.escape(real_basedir)}.*/ =~ path
      raise R10K::Error.new("#{dirname}: Puppetfile cannot manage content '#{modname}' outside of containing environment: #{path} is not within #{real_basedir}")
    end

    true
  end

  def dirname
    File.basename(@basedir)
  end

  class DSL
    # A barebones implementation of the Puppetfile DSL
    #
    # @api private

    def initialize(librarian)
      @librarian = librarian
    end

    def mod(name, args = nil)
      @librarian.add_module(name, args)
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
