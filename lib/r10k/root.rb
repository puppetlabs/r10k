require 'r10k'
require 'r10k/module'
require 'r10k/synchro/git'

class R10K::Root

  # @!attribute [r] name
  #   The directory name of this root
  attr_reader :name

  # @!attribute [r] basedir
  #   The basedir to clone the root into
  attr_reader :basedir

  # @!attribute [r] remote
  #   The location of the remote git repository
  attr_reader :remote

  # @!attribute [r] ref
  #   The git ref to instantiate into the basedir
  attr_reader :ref

  def initialize(hash)
    parse_initialize_hash(hash)
  end

  def sync!(options = {})
    synchro = R10K::Synchro::Git.new(@remote)
    recursive_needed = !(synchro.cloned?(full_path))
    synchro.sync(full_path, @ref, options)

    sync_modules!(options) if recursive_needed
  end

  def sync_modules!(options = {})
    modules.each do |mod|
      mod.sync!(options)
    end
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
    puts "#{self}: #{full_path} does not exist, cannot enumerate modules."
    []
  end

  def full_path
    File.expand_path(File.join @basedir, @name)
  end

  private

  def parse_initialize_hash(hash)
    if hash['name']
      @name = hash.delete('name')
    elsif hash['ref']
      @name = hash['ref']
    else
      raise "Unable to resolve directory name from options #{hash.inspect}"
    end

    # XXX This could be metaprogrammed, but it seems like the road to madness.

    if hash['basedir']
      @basedir = hash.delete('basedir')
    else
      raise "'basedir' is a required value for #{self.class}.new"
    end

    if hash['remote']
      @remote = hash.delete('remote')
    else
      raise "'remote' is a required value for #{self.class}.new"
    end

    if hash['ref']
      @ref = hash.delete('ref')
    else
      raise "'ref' is a required value for #{self.class}.new"
    end

    unless hash.empty?
      raise "#{self.class}.new only expects keys ['name', 'basedir', 'remote', 'ref'], got #{hash.keys.inspect}"
    end
  end
end
