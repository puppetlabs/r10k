require 'r10k/puppetfile'
require 'r10k/action/base'
require 'r10k/errors/formatting'

module R10K
  module Action
    module Puppetfile
      class Check < R10K::Action::Base

        def call
          pf = R10K::Puppetfile.new(@root, @moduledir, @puppetfile)
          begin
            pf.load!
            $stderr.puts _("Syntax OK")
            true
          rescue => e
            $stderr.puts R10K::Errors::Formatting.format_exception(e, @trace)
            false
          end
        end

        private

        def allowed_initialize_opts
          super.merge(root: :self, puppetfile: :self, moduledir: :self)
        end
      end
    end
  end
end

