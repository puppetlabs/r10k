require 'r10k/module'
require 'r10k/git'

class R10K::Module::Git < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a? Hash and args.has_key?(:git)
  rescue
    false
  end

  # @!attribute [r] working_dir
  #   @api private
  #   @return [R10K::Git::WorkingDir]
  attr_reader :working_dir

  def initialize(name, basedir, args)
    @name, @basedir, @args = name, basedir, args

    parse_options(args)

    @working_dir = R10K::Git::WorkingDir.new(@ref, @remote, @basedir, @name)
  end

  def version
    @ref
  end

  def sync
    @working_dir.sync
  end

  def status
    if not @working_dir.exist?
      :absent
    elsif not @working_dir.git?
      :mismatched
    elsif not @remote == @working_dir.remote
      :mismatched
    else
      :insync
    end
  end

  def parse_options(options)
    @remote = options.delete(:git)

    cache = R10K::Git::Cache.generate(@remote)

    if options[:branch]
      @ref = R10K::Git::Head.new(options.delete(:branch), cache)
    end

    if options[:tag]
      @ref = R10K::Git::Tag.new(options.delete(:tag), cache)
    end

    if options[:ref]
      @ref = R10K::Git::Ref.new(options.delete(:ref), cache)
    end

    @ref ||= R10K::Git::Ref.new('master', cache)

    unless options.empty?
      raise ArgumentError, "Unhandled options #{options.keys.inspect} given to #{self.class}#parse_options"
    end
  end
end
