require 'r10k/puppetfile'
require 'r10k/errors/formatting'
require 'r10k/action/visitor'
require 'r10k/action/base'
require 'r10k/util/cleaner'

module R10K
  module Action
    module Puppetfile
      class Install < R10K::Action::Base

        def call
          @ok = true
          begin
            pf = R10K::Puppetfile.new(@root,
                                      {moduledir: @moduledir,
                                       puppetfile_path: @puppetfile,
                                       force: @force || false})
            pf.load!
            pf.sync

            R10K::Util::Cleaner.new(pf.managed_directories,
                                    pf.desired_contents,
                                    pf.purge_exclusions).purge!

          rescue => e
            @ok = false
            logger.error R10K::Errors::Formatting.format_exception(e, @trace)
          end

          @ok
        end

        private

        def allowed_initialize_opts
          super.merge(root: :self, puppetfile: :self, moduledir: :self, force: :self )
        end
      end
    end
  end
end
