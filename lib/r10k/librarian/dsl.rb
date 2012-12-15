require 'r10k/librarian'

class R10K::Librarian::DSL

  def initialize(librarian)
    @librarian = librarian
  end

  def mod(name, *args)
    @librarian.add_module(name, args)
  end

  def forge(location)
    @librarian.set_forge(location)
  end

  def method_missing(method, *args)
    raise Exception, "unrecognized declaration '#{method}'"
  end
end
