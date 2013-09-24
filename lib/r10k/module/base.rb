require 'r10k/module'

class R10K::Module::Base
  attr_accessor :name, :basedir

  # @return [String] The full filesystem path to the module.
  def full_path
    File.join(@basedir, @name)
  end
end
