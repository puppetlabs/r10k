require 'r10k/module'
require 'r10k/puppetfile/dsl'

module R10K
class Puppetfile
  # Defines the data members of a Puppetfile

  # @!attribute [r] forge
  #   @return [String] The URL to use for the Puppet Forge
  attr_reader :forge

  # @!attribute [r] modules
  #   @return [Array<R10K::Module>]
  attr_reader :modules

  def initialize(path)
    @path    = path
    @modules = []
    @forge   = 'forge.puppetlabs.com'
  end

  def load
    dsl = R10K::Puppetfile::DSL.new(self)
    dsl.instance_eval(puppetfile_contents, @path)

    @modules
  end

  # This method only exists because people tried being excessively clever.
  def set_forge(forge)
    @forge = forge
  end

  def add_module(name, args)
    @modules << [name, args]
  end

  private

  def puppetfile_contents
    File.read(@path)
  end

  class DSL
    # A barebones implementation of the Puppetfile DSL
    #
    # @api private

    def initialize(librarian)
      @librarian = librarian
    end

    def mod(name, args = [])
      @librarian.add_module(name, args)
    end

    def forge(location)
      @librarian.set_forge(location)
    end

    def method_missing(method, *args)
      raise NoMethodError, "unrecognized declaration '#{method}'"
    end
  end
end
end
