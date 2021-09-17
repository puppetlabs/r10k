require 'r10k/module'

# A dummy module type that can be used to "protect" Puppet modules that exist
# inside of the Puppetfile "moduledir" location. Local modules will not be
# modified, and will not be purged when r10k removes unmanaged modules.
class R10K::Module::Local < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a?(Hash) && (args[:local] || args[:type].to_s == 'local')
  end

  def self.statically_defined_version(*)
    "0.0.0"
  end

  def version
    self.class.statically_defined_version
  end

  def properties
    {
      :expected => "0.0.0 (local)",
      :actual   => "0.0.0 (local)",
      :type     => :forge,
    }
  end

  def status
    :insync
  end

  # @param [Hash] opts Deprecated
  # @return [Boolean] false, because local modules are always considered in-sync
  def sync(opts={})
    logger.debug1 _("Module %{title} is a local module, always indicating synced.") % {title: title}
    false
  end
end
