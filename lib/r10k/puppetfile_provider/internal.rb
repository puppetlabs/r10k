require 'r10k/puppetfile'
require 'r10k/puppetfile_provider/driver'

module R10K
module PuppetfileProvider
  class Internal < Driver

    def sync_modules
      puppetfile.load
      puppetfile.modules.each { |mod| mod.sync }
    end

    def sync
      sync_modules
      purge
    end

    def purge
      moduledir = puppetfile.moduledir
      puppetfile.load

      stale_mods = puppetfile.stale_contents

      if stale_mods.empty?
        logger.debug "No stale modules in #{moduledir}"
      else
        logger.info "Purging stale modules from #{moduledir}"
        logger.debug "Stale modules in #{moduledir}: #{stale_mods.join(', ')}"
        puppetfile.purge!
      end
    end

    private

    def puppetfile
      @puppetfile ||=  R10K::Puppetfile.new(@basedir, @moduledir, @puppetfile_path)
    end

  end
end
end
