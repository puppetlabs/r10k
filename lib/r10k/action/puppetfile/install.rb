require 'r10k/action/base'
require 'r10k/content_synchronizer'
require 'r10k/errors/formatting'
require 'r10k/module_loader/puppetfile'
require 'r10k/util/cleaner'

module R10K
  module Action
    module Puppetfile
      class Install < R10K::Action::Base

        def call
          begin
            options = { basedir: @root, overrides: { force: @force || false } }
            options[:moduledir]  = @moduledir  if @moduledir
            options[:puppetfile] = @puppetfile if @puppetfile

            loader = R10K::ModuleLoader::Puppetfile.new(**options)
            loaded_content = loader.load

            pool_size = @settings[:pool_size] || 4
            modules   = loaded_content[:modules]
            if pool_size > 1
              R10K::ContentSynchronizer.concurrent_sync(modules, pool_size, logger)
            else
              R10K::ContentSynchronizer.serial_sync(modules, logger)
            end

            R10K::Util::Cleaner.new(loaded_content[:managed_directories],
                                    loaded_content[:desired_contents],
                                    loaded_content[:purge_exclusions]).purge!

            true
          rescue => e
            logger.error R10K::Errors::Formatting.format_exception(e, @trace)
            false
          end
        end

        private

        def allowed_initialize_opts
          super.merge(root: :self, puppetfile: :self, moduledir: :self, force: :self )
        end
      end
    end
  end
end
