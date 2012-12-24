require 'r10k'
require 'r10k/module'

class R10K::Module::Forge < R10K::Module

  def self.implements(name, args)
    args.is_a? String and args.match /\d+\.\d+\.\d+/
  end

  def initialize(name, path, args)
    super

    @version = @args
  end

  def sync!(options = {})
    puts "#{self.class.name}#sync! is not implemented. Doing nothing."
  end
end
