require 'r10k/action/base'
require 'r10k/errors/formatting'
require 'r10k/module_loader/puppetfile'
require 'r10k/util/cleaner'

module R10K
  module Action
    module Puppetfile
      class Purge < R10K::Action::Base

        def call
          options = { basedir: @root }

          options[:moduledir]  = @moduledir  if @moduledir
          options[:puppetfile] = @puppetfile if @puppetfile

          loader = R10K::ModuleLoader::Puppetfile.new(**options)
          loaded_content = loader.load
          R10K::Util::Cleaner.new(loaded_content[:managed_directories],
                                  loaded_content[:desired_contents],
                                  loaded_content[:purge_exclusions]).purge!

          true
        rescue => e
          logger.error R10K::Errors::Formatting.format_exception(e, @trace)
          false
        end

        private

        def allowed_initialize_opts
          super.merge(root: :self, puppetfile: :self, moduledir: :self)
        end
      end
    end
  end
end
