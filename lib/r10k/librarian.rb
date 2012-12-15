require 'r10k'

class R10K::Librarian

  def initialize(puppetfile)
    @puppetfile = puppetfile
  end

  def load
    dsl = R10K::Librarian::DSL.new(self)
    dsl.instance_eval(File.read(@puppetfile), @puppetfile)
  end

  # This method only exists because people tried being excessively clever.
  def set_forge(forge)

  end

  def add_module(*args)
    puts "YAY #{args.inspect}"
  end
end

require 'r10k/librarian/dsl'
