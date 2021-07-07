module R10K
  module ContentSynchronizer

    def self.serial_accept(modules, visitor, loader)
      visitor.visit(:puppetfile, loader) do
        serial_sync(modules)
      end
    end

    def self.serial_sync(modules)
      sync_error = non_raising_sync(modules)

      raise sync_error if sync_error
    end

    def self.concurrent_accept(modules, visitor, loader, pool_size, logger)
      mods_queue = modules_visit_queue(modules, visitor, loader)
      sync_queue(mods_queue, pool_size, logger)
    end

    def self.concurrent_sync(modules, pool_size, logger)
      mods_queue = modules_sync_queue(modules)
      sync_queue(mods_queue, pool_size, logger)
    end

    def self.sync_queue(mods_queue, pool_size, logger)
      logger.debug _("Updating modules with %{pool_size} threads") % {pool_size: pool_size}
      thread_pool = pool_size.times.map { sync_thread(mods_queue, logger) }
      thread_exception = nil

      # If any threads raise an exception the deployment is considered a failure.
      # In that event clear the queue, wait for other threads to finish their
      # current work, then re-raise the first exception caught.
      begin
        thread_pool.each(&:join)
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

    def self.sync_thread(mods_queue, logger)
      Thread.new do
        begin
          sync_error = nil
          while mods = mods_queue.pop(raise_threaderror_when_complete = true) do
            sync_error ||= non_raising_sync(mods)
          end

        rescue => e
          if sync_error
            logger.debug _("Module thread %{id} failed") % {id: Thread.current.object_id}
            Thread.main.raise(sync_error)
          elsif e.is_a?(ThreadError)
            logger.debug _("Module thread %{id} exiting: %{message}") % {message: e.message, id: Thread.current.object_id}
            Thread.exit
          else
            Thread.main.raise(e)
          end
        end
      end
    end

    def self.non_raising_sync(modules)
      error = nil
      modules.each do |mod|
        begin
          mod.sync
        rescue => e
          error = e
        end
      end

      return error
    end
  end
end
