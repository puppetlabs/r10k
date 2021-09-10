require 'r10k/module'

class R10K::Module::Definition < R10K::Module::Base

  attr_reader :version

  def initialize(name, dirname:, args:, implementation:, environment: nil)
    @original_name  = name
    @original_args  = args.dup
    @implementation = implementation
    @version        = implementation.statically_defined_version(name, args)

    super(name, dirname, args, environment)
  end

  def to_implementation
    mod = @implementation.new(@title, @dirname, @original_args, @environment)

    mod.origin = origin
    mod.spec_deletable = spec_deletable

    mod
  end

  # syncing is a noop for module definitions
  # Returns false to inidicate the module was not updated
  def sync(args = {})
    logger.debug1(_("Not updating module %{name}, assuming content unchanged") % {name: name})
    false
  end

  def status
    :insync
  end

  def properties
    type = nil

    if @args[:type]
      type = @args[:type]
    elsif @args[:ref] || @args[:commit] || @args[:branch] || @args[:tag]
      type = 'git'
    elsif @args[:svn]
      # This logic is clear and included for completeness sake, though at
      # this time module definitions do not support SVN versions.
      type = 'svn'
    else
      type = 'forge'
    end

    {
      expected: version,
      # We can't get the value for `actual` here because that requires the
      # implementation (and potentially expensive operations by the
      # implementation). Some consumers will check this value, if it exists
      # and if not, fall back to the expected version. That is the correct
      # behavior when assuming modules are unchanged, and why `actual` is set
      # to `nil` here.
      actual: nil,
      type: type
    }
  end
end

