require 'r10k/module'

class R10K::Module::Local < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a? Symbol and args == :local
  end

  def initialize(name, dirname, opts)
    super
  end

  def status
    :insync
  end

  def sync
  end

  private

  def parse_title(title)
    ["", title]
  end

end
