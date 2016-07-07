require 'r10k/module'
require 'r10k/logging'

# A dummy module type that can be used to "protect" Puppet modules that exist
# inside of the Puppetfile "moduledir" location. Local modules will not be
# modified, and will not be purged when r10k removes unmanaged modules.
class R10K::Module::Local < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a?(Hash) && args[:local]
  end

  include R10K::Logging

  def version
    "0.0.0"
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

  def sync
    logger.debug1 _("Module %{title} is a local module, always indicating synced.") % {title: title}
  end
end
