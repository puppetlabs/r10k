require 'r10k/module'
require 'r10k/git'
require 'r10k/git/stateful_repository'
require 'forwardable'

class R10K::Module::Git < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.has_key?(:git) || args[:type].to_s == 'git'
  end

  # Will be called if self.implement? above returns true. Will return
  # the version info, if version is statically defined in the modules
  # declaration.
  def self.statically_defined_version(name, args)
    if !args[:type] && (args[:ref] || args[:tag] || args[:commit])
      if args[:ref] && args[:ref].to_s.match(/[0-9a-f]{40}/)
        args[:ref]
      else
        args[:tag] || args[:commit]
      end
    elsif args[:type].to_s == 'git' && args[:version] && args[:version].to_s.match(/[0-9a-f]{40}/)
      args[:version]
    end
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
      :version                 => :desired_ref,
      :source                  => :remote,
      :type                    => ::R10K::Util::Setopts::Ignore,

      # Type-specific options
      :branch                  => :desired_ref,
      :tag                     => :desired_ref,
      :commit                  => :desired_ref,
      :ref                     => :desired_ref,
      :git                     => :remote,
      :default_branch          => :default_branch,
      :default_branch_override => :default_override_ref,
    }, :raise_on_unhandled => false)

    @default_ref = @default_branch.nil? ? @overrides.dig(:modules, :default_ref) : @default_branch
    force = @overrides[:force]
    @force = force == false ? false : true

    if @desired_ref == :control_branch
      if @environment && @environment.respond_to?(:ref)
        @desired_ref = @environment.ref
      else
        logger.warn _("Cannot track control repo branch for content '%{name}' when not part of a git-backed environment, will use default if available." % {name: name})
      end
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
  # @return [Boolean] true if the module was updated, false otherwise
  def sync(opts={})
    force = opts[:force] || @force
    if should_sync?
      updated = @repo.sync(version, force, @exclude_spec)
    else
      updated = false
    end
    maybe_delete_spec_dir
    maybe_extra_delete
    updated
  end

  def status
    @repo.status(version)
  end

  def cachedir
    @repo.cache.sanitized_dirname
  end

  def validate_ref_defined
    if @desired_ref.nil? && @default_ref.nil? && @default_override_ref.nil?
      msg = "No ref defined for module #{@name}. Add a ref to the module definition "
      msg << "or set git:default_ref in the r10k.yaml config to configure a global default ref."
      raise ArgumentError, msg
    end
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
        msg << "and no default provided. r10k no longer hardcodes 'master' as the default ref."
        msg << "Consider setting a ref per module in the Puppetfile or setting git:default_ref"
        msg << "in your r10k config."
      end

      raise ArgumentError, _(msg.join(' ')) % vars
    end
  end
end
