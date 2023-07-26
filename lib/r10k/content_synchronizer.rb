module R10K
  module ContentSynchronizer

    def self.serial_accept(modules, visitor, loader)
      visitor.visit(:puppetfile, loader) do
        serial_sync(modules)
      end
    end

    def self.serial_sync(modules)
      updated_modules = []
      modules.each do |mod|
        updated = mod.sync
        updated_modules << mod.name if updated
      end
      updated_modules
    end

    # Returns a Queue of the names of modules actually updated
    def self.concurrent_accept(modules, visitor, loader, pool_size, logger)
      mods_queue = modules_visit_queue(modules, visitor, loader)
      sync_queue(mods_queue, pool_size, logger)
    end

    # Returns a Queue of the names of modules actually updated
    def self.concurrent_sync(modules, pool_size, logger)
      mods_queue = modules_sync_queue(modules)
      sync_queue(mods_queue, pool_size, logger)
    end

    # Returns a Queue of the names of modules actually updated
    def self.sync_queue(mods_queue, pool_size, logger)
      logger.debug _("Updating modules with %{pool_size} threads") % {pool_size: pool_size}
      updated_modules = Queue.new
      thread_pool = pool_size.times.map { sync_thread(mods_queue, logger, updated_modules) }
      thread_exception = nil

      # If any threads raise an exception the deployment is considered a failure.
      # In that event clear the queue, wait for other threads to finish their
      # current work, then re-raise the first exception caught.
      begin
        thread_pool.each(&:join)
        # Return the list of all modules that were actually updated
        updated_modules
      rescue => e
        logger.error _("Error during concurrent deploy of a module: %{message}") % {message: e.message}
        mods_queue.clear
        thread_exception ||= e
        retry
      ensure
        raise thread_exception unless thread_exception.nil?
      end
    end

    def self.modules_visit_queue(modules, visitor, loader)
      Queue.new.tap do |queue|
        visitor.visit(:puppetfile, loader) do
          enqueue_modules(queue, modules)
        end
      end
    end

    def self.modules_sync_queue(modules)
      Queue.new.tap do |queue|
        enqueue_modules(queue, modules)
      end
    end

    def self.enqueue_modules(queue, modules)
      modules_by_cachedir = modules.group_by { |mod| mod.cachedir }
      modules_without_vcs_cachedir = modules_by_cachedir.delete(:none) || []

      modules_without_vcs_cachedir.each {|mod| queue << Array(mod) }
      modules_by_cachedir.values.each {|mods| queue << mods }
    end

    def self.sync_thread(mods_queue, logger, updated_modules)
      Thread.new do
        begin
          while mods = mods_queue.pop(true) do
            mods.each do |mod|
              begin
                updated = mod.sync
                updated_modules << mod.name if updated
              rescue Exception => e
                logger.error _("Module %{mod_name} failed to synchronize due to %{message}") % {mod_name: mod.name, message: e.message}
                raise e
              end
            end
          end
        rescue ThreadError => e
          logger.debug _("Module thread %{id} exiting: %{message}") % {message: e.message, id: Thread.current.object_id}
          Thread.exit
        rescue => e
          Thread.main.raise(e)
        end
      end
    end
  end
end
