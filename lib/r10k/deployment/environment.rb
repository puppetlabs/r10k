require 'r10k/module'
require 'r10k/logging'

module R10K
class Deployment
class Environment

  include R10K::Logging

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
    working_dir = R10K::Git::WorkingDir.new(@remote)
    recursive_needed = !(working_dir.cloned?(full_path))
    working_dir.sync(full_path, @ref, options)

    sync_modules!(options) if recursive_needed
  end

  def sync_modules!(options = {})
    modules.each do |mod|
      mod.sync!(options)
    end
  end

  def puppetfile
    @puppetfile = R10K::Puppetfile.new(full_path)
  end

  def modules
    puppetfile.load
    @modules
  end

  def full_path
    @full_path ||= File.expand_path(File.join @basedir, @name)
  end

  private

  def parse_initialize_hash(hash)
    if hash[:name]
      @name = hash.delete(:name)
    elsif hash[:ref]
      @name = hash[:ref]
    else
      raise "Unable to resolve directory name from options #{hash.inspect}"
    end

    # XXX This could be metaprogrammed, but it seems like the road to madness.

    if hash[:basedir]
      @basedir = hash.delete(:basedir)
    else
      raise ":basedir is a required value for #{self.class}.new"
    end

    if hash[:remote]
      @remote = hash.delete(:remote)
    else
      raise ":remote is a required value for #{self.class}.new"
    end

    if hash[:ref]
      @ref = hash.delete(:ref)
    else
      raise ":ref is a required value for #{self.class}.new"
    end

    unless hash.empty?
      raise "#{self.class}.new only expects keys [:name, :basedir, :remote, :ref], got #{hash.keys.inspect}"
    end
  end
end
end
end
