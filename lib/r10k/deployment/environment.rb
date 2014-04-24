require 'r10k/deployment'
require 'r10k/environment'

class R10K::Deployment::Environment

  # @param [String] ref
  # @param [String] remote
  # @param [String] basedir
  # @param [String] dirname The directory to clone the root into, defaults to ref
  # @param [String] source_name An additional string which may be used with ref to build dirname
  def self.new(ref, remote, basedir, dirname = nil, source_name = "")
    alternate_name =  source_name.empty? ? ref : source_name + "_" + ref
    dirname = dirname || alternate_name

    R10K::Environment::Git.new(basedir, ref, {:remote => remote, :ref => ref})
  end
end
