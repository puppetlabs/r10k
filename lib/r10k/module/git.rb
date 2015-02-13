require 'r10k/module'
require 'r10k/git'
require 'r10k/git/stateful_repository'

class R10K::Module::Git < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a? Hash and args.has_key?(:git)
  rescue
    false
  end

  # @!attribute [r] repo
  #   @api private
  #   @return [R10K::Git::StatefulRepository]
  attr_reader :repo

  def initialize(title, dirname, args)
    super
    parse_options(@args)
    @repo = R10K::Git::StatefulRepository.new(@ref, @remote, @dirname, @name)
  end

  def version
    @ref
  end

  def properties
    {
      :expected => @ref,
      :actual   => (@repo.head || "(unresolvable)"),
      :type     => :git,
    }
  end

  def sync
    @repo.sync
  end

  def status
    @repo.status
  end

  private

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
