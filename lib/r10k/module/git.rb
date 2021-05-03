require 'r10k/module'
require 'r10k/git'
require 'r10k/git/stateful_repository'
require 'forwardable'

class R10K::Module::Git < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.has_key?(:git) || args[:type].to_s == 'git'
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

  # @!attribute [r] default_override_ref
  #   @api private
  #   @return [String]
  attr_reader :default_override_ref

  include R10K::Util::Setopts

  def initialize(title, dirname, opts, environment=nil)
    super
    setopts(opts, {
      # Standard option interface
      :version   => :desired_ref,
      :source    => :remote,
      :type      => ::R10K::Util::Setopts::Ignore,
      :overrides => :self,

      # Type-specific options
      :branch    => :desired_ref,
      :tag       => :desired_ref,
      :commit    => :desired_ref,
      :ref       => :desired_ref,
      :git       => :remote,
      :default_branch          => :default_ref,
      :default_branch_override => :default_override_ref,
    })

    force = @overrides && @overrides.dig(:modules, :force)
    @force = force == false ? false : true

    @desired_ref ||= 'master'

    if @desired_ref == :control_branch && @environment && @environment.respond_to?(:ref)
      @desired_ref = @environment.ref
    end

    @repo = R10K::Git::StatefulRepository.new(@remote, @dirname, @name)
  end

  def version
    validate_ref(@desired_ref, @default_ref, @default_override_ref)
  end

  def properties
    {
      :expected => version,
      :actual   => (@repo.head || "(unresolvable)"),
      :type     => :git,
    }
  end

  # @param [Hash] opts Deprecated
  def sync(opts={})
    super

    force = opts[:force] || @force
    @repo.sync(version, force)
  end

  def status
    @repo.status(version)
  end

  def cachedir
    @repo.cache.sanitized_dirname
  end

  private

  def validate_ref(desired, default, default_override)
    if desired && desired != :control_branch && @repo.resolve(desired)
      return desired
    elsif default_override && @repo.resolve(default_override)
      return default_override
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

      if default_override
        msg << "or resolve the default branch override '%{default_override}',"
        vars[:default_override] = default_override
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
end
