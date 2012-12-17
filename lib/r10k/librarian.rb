require 'r10k'

class R10K::Librarian

  attr_reader :forge

  def initialize(puppetfile)
    @puppetfile = puppetfile
    @modules    = []
    @forge      = 'forge.puppetlabs.com'
  end

  def load
    dsl = R10K::Librarian::DSL.new(self)
    dsl.instance_eval(File.read(@puppetfile), @puppetfile)

    @modules
  end

  # This method only exists because people tried being excessively clever.
  def set_forge(forge)
    @forge = forge
  end

  def add_module(name, args)
    @modules << [name, args[0]]
  end
end

require 'r10k/librarian/dsl'
