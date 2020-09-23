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

  # @!attribute [r] repo
  #   @api private
  #   @return [R10K::Git::StatefulRepository]
  attr_reader :repo

  # @!attribute [r] desired_ref
  #   @api private
  #   @return [String]
  attr_reader :desired_ref

  # @!attribute [r] default_ref
  #   @api private
  #   @return [String]
  attr_reader :default_ref

  def initialize(title, dirname, args, environment=nil)
    super

    parse_options(@args)

    @repo = R10K::Git::StatefulRepository.new(@remote, @dirname, @name)
  end

  def version
    validate_ref(@desired_ref, @default_ref)
  end

  def properties
    {
      :expected => version,
      :actual   => (@repo.head || "(unresolvable)"),
      :type     => :git,
    }
  end

  def sync(opts={})
    force = opts && opts.fetch(:force, true)
    @repo.sync(version, force)
  end

  def status
    @repo.status(version)
  end

  def cachedir
    @repo.cache.sanitized_dirname
  end

  private

  def validate_ref(desired, default)
    if desired && desired != :control_branch && @repo.resolve(desired)
      return desired
    elsif default && @repo.resolve(default)
      return default
    else
      msg = ["Unable to manage Puppetfile content '%{name}':"]
      vars = {name: @name}

      if desired == :control_branch
        msg << "Could not resolve control repo branch"
      elsif desired
        msg << "Could not resolve desired ref '%{desired}'"
        vars[:desired] = desired
      else
        msg << "Could not determine desired ref"
      end

      if default
        msg << "or resolve default ref '%{default}'"
        vars[:default] = default
      else
        msg << "and no default provided"
      end

      raise ArgumentError, _(msg.join(' ')) % vars
    end
  end

  def parse_options(options)
    ref_opts = [:branch, :tag, :commit, :ref]
    known_opts = [:git, :default_branch] + ref_opts

    unhandled = options.keys - known_opts
    unless unhandled.empty?
      raise ArgumentError, _("Unhandled options %{unhandled} specified for %{class}") % {unhandled: unhandled, class: self.class}
    end

    @remote = options[:git]

    @desired_ref = ref_opts.find { |key| break options[key] if options.has_key?(key) } || 'master'
    @default_ref = options[:default_branch]

    if @desired_ref == :control_branch && @environment && @environment.respond_to?(:ref)
      @desired_ref = @environment.ref
    elsif @desired_ref == :control_branch && @environment.is_a?(String)
      @desired_ref = @environment
    end
  end
end
