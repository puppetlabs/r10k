require 'r10k/module'
require 'r10k/hg/stateful_repository'
require 'forwardable'

class R10K::Module::Hg < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a? Hash and args.has_key?(:hg)
  rescue
    false
  end

  # @!attribute [r] repo
  #   @api private
  #   @return [R10K::Hg::StatefulRepository]
  attr_reader :repo

  def initialize(title, dirname, args)
    super
    parse_options(@args)

    repo_options = {}
    repo_options[:ref_type] = @ref_type if @ref_type

    @repo = R10K::Hg::StatefulRepository.new(@rev, @remote, @dirname, @name, repo_options)
  end

  def version
    @rev
  end

  def properties
    {
      :expected => @rev,
      :actual   => (@repo.head || "(unresolvable)"),
      :type     => :hg,
    }
  end

  extend Forwardable

  def_delegators :@repo, :sync, :status

  private

  def parse_options(options)
    @remote = options.delete(:hg)

    if options[:branch]
      @rev = options.delete(:branch)
      @ref_type = :branch
    end

    if options[:bookmark]
      @rev = options.delete(:bookmark)
      @ref_type = :bookmark
    end

    if options[:tag]
      @rev = options.delete(:tag)
    end

    if options[:changeset]
      @rev = options.delete(:changeset)
    end

    if options[:rev]
      @rev = options.delete(:rev)
    end

    unless @rev
      @rev = 'default'
      @ref_type = :branch
    end

    unless options.empty?
      raise ArgumentError, "Unhandled options #{options.keys.inspect} specified for #{self.class}"
    end
  end
end
