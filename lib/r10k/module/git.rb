require 'r10k/module'
require 'r10k/git'
require 'r10k/git/stateful_repository'
require 'forwardable'

class R10K::Module::Git < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a? Hash and args.has_key?(:git)
  rescue
    false
  end

  def self.parse_options(options)
    parsed = {}

    parsed[:remote] = options.delete(:git)

    if options[:branch]
      ref = options.delete(:branch)
    end

    if options[:tag]
      ref = options.delete(:tag)
    end

    if options[:commit]
      ref = options.delete(:commit)
    end

    if options[:ref]
      ref = options.delete(:ref)
    end

    parsed[:ref] = ref || 'master'

    unless options.empty?
      raise ArgumentError, "Unhandled options #{options.keys.inspect} specified for #{self}"
    end

    return parsed
  end

  # @!attribute [r] repo
  #   @api private
  #   @return [R10K::Git::StatefulRepository]
  attr_reader :repo

  def initialize(title, dirname, args)
    super
    @remote, @ref = self.class.parse_options(@args).values_at(:remote, :ref)
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

  extend Forwardable

  def_delegators :@repo, :sync, :status
end
