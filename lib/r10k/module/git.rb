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

  private

  def validate_ref(desired, default)
    if desired && @repo.resolve(desired)
      return desired
    elsif default && @repo.resolve(default)
      return default
    else
      if default
        raise ArgumentError, _("Unable to manage Puppetfile content '%{name}': Could not resolve desired ref '%{desired}' or default ref '%{default}'") % {name: @name, desired: desired, default: default}
      else
        raise ArgumentError, _("Unable to manage Puppetfile content '%{name}': Could not resolve desired ref '%{desired}' and no default given") % {name: @name, desired: desired}
      end
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

    if @desired_ref == :control_branch
      if @environment && @environment.respond_to?(:ref)
        @desired_ref = @environment.ref
      else
        raise ArgumentError, _("Cannot track control repo branch from Puppetfile in this context: environment is nil or did not provide a valid ref")
      end
    end
  end
end
