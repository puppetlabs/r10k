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

    @full_path = Pathname.new(File.join(basedir, name))

    @working_dir = R10K::Git::WorkingDir.new(@ref, @remote, @basedir, @name)
  end

  def version
    @ref
  end

  def sync
    case status
    when :absent
      install
    when :mismatched
      uninstall
      install
    when :outdated
      @working_dir.sync
    end
  end

  def status
    if not @working_dir.exist?
      return :absent
    elsif not @working_dir.git?
      return :mismatched
    elsif not @remote == @working_dir.remote
      return :mismatched
    end

    if @working_dir.outdated?
      return :outdated
    end

    return :insync
  end

  private

  def install
    @working_dir.sync
  end

  def uninstall
    @full_path.rmtree
  end

  def parse_options(options)
    @remote = options.delete(:git)

    if options[:branch]
      @ref = R10K::Git::Head.new(options.delete(:branch))
    end

    if options[:tag]
      @ref = R10K::Git::Tag.new(options.delete(:tag))
    end

    if options[:commit]
      @ref = R10K::Git::Commit.new(options.delete(:commit))
    end

    if options[:ref]
      @ref = R10K::Git::Ref.new(options.delete(:ref))
    end

    @ref ||= R10K::Git::Ref.new('master')

    unless options.empty?
      raise ArgumentError, "Unhandled options #{options.keys.inspect} specified for #{self.class}"
    end
  end
end
