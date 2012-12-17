require 'r10k'

module R10K::Module

  def self.register(klass)
    @klasses ||= []
    @klasses << klass
  end

  def self.new(name, path, args)
    if implementing_klass = @klasses.find { |klass| klass.implements(name, args) }
      implementing_klass.new(name, path, args)
    else
      raise "Module #{name} with args #{args.inspect} can't be recognized."
    end
  end
end

require 'r10k/module/git'
require 'r10k/module/forge'
