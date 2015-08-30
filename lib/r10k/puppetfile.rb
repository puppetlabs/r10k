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

  # @param [String] basedir
  # @param [String] puppetfile The path to the Puppetfile, default to #{basedir}/Puppetfile
  def initialize(basedir, moduledir = nil, puppetfile = nil)
    @basedir         = basedir
    @moduledir       = moduledir  || File.join(basedir, 'modules')
    @puppetfile_path = puppetfile || File.join(basedir, 'Puppetfile')

    @modules = []
    @forge   = 'forgeapi.puppetlabs.com'
  end

  def load
    if File.readable? @puppetfile_path
      self.load!
    else
      logger.debug "Puppetfile #{@puppetfile_path.inspect} missing or unreadable"
    end
  end

  def load!
    dsl = R10K::Puppetfile::DSL.new(self)
    dsl.instance_eval(puppetfile_contents, @puppetfile_path)
  rescue SyntaxError, LoadError => e
    raise R10K::Error.wrap(e, "Failed to evaluate #{@puppetfile_path}")
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
      File.join(basedir, moduledir)
    end
  end

  # @param [String] name
  # @param [*Object] args
  def add_module(name, args)
    @modules << R10K::Module.new(name, @moduledir, args)
    if @modules[-1].respond_to? :forge
      @modules[-1].forge = @forge
    end
  end

  include R10K::Util::Purgeable

  def managed_directory
    @moduledir
  end

  # List all modules that should exist in the module directory
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    @modules.map { |mod| mod.name }
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
      raise NoMethodError, "unrecognized declaration '#{method}'"
    end
  end
end
end
