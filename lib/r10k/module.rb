require 'r10k'

module R10K::Module

  # Register an inheriting  class for later generation
  def self.included(klass)
    klass.extend self
    @klasses ||= []
    @klasses << klass
  end

  # Look up the implementing class and instantiate an object
  #
  # This method takes the arguments for normal object generation and checks all
  # inheriting classes to see if they implement the behavior needed to create
  # the requested object. It selects the first class that can implement an object
  # with `name, args`, and generates an object of that class.
  #
  # @param [String] name The unique name of the module
  # @param [String] basedir The root to install the module in
  # @param [Object] args An arbitary value or set of values that specifies the implementation
  #
  # @return [Object < R10K::Module] A member of the implementing subclass
  def self.new(name, basedir, args)
    if implementation = @klasses.find { |klass| klass.implement?(name, args) }
      obj = implementation.new(name, basedir, args)
      obj
    else
      raise "Module #{name} with args #{args.inspect} doesn't have an implementation. (Are you using the right arguments?)"
    end
  end

  attr_accessor :name, :basedir

  # @return [String] The full filesystem path to the module.
  def full_path
    File.join(@basedir, @name)
  end
end

require 'r10k/module/git'
require 'r10k/module/forge'
