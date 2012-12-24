require 'r10k'
require 'r10k/module'
require 'r10k/synchro/git'

class R10K::Root

  # @!attribute [r] name
  #   The directory name of this root
  attr_reader :name

  # @!attribute [r] path
  #   The path to clone the root into
  attr_reader :path

  # @!attribute [r] source
  #   The location of the remote git repository
  attr_reader :source

  # @!attribute [r] branch
  #   The git branch to instantiate into the path
  attr_reader :branch

  def initialize(name, path, source, branch)
    @name, @path, @source, @branch = name, path, source, branch
  end

  def sync!(options = {})
    synchro = R10K::Synchro::Git.new(@source)
    synchro.sync(full_path, @branch, options)
  end

  def modules
    librarian = R10K::Librarian.new("#{full_path}/Puppetfile")

    module_data = librarian.load

    @modules = module_data.map do |mod|
      name = mod[0]
      args = mod[1]
      R10K::Module.new(name, "#{full_path}/modules", args)
    end
  rescue Errno::ENOENT
    []
  end

  def full_path
    File.expand_path(File.join @path, @name)
  end
end
