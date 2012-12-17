require 'r10k'
require 'r10k/module'

class R10K::Module::Forge

  R10K::Module.register(self)

  def self.implements(name, args)
    args.is_a? String and args.match /\d+\.\d+\.\d+/
  end

  def initialize(name, path, args)
    @name = name
    @path = path
    @version = args
  end

  def sync!
    puts "#{self.class.name}#sync! is not implemented. Doing nothing."
  end

  private

  def full_path
    File.join(@name, @path)
  end
end
