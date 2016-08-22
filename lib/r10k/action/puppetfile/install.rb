require 'r10k/puppetfile'
require 'r10k/errors/formatting'
require 'r10k/action/visitor'
require 'r10k/action/base'

module R10K
  module Action
    module Puppetfile
      class Install < R10K::Action::Base

        def call
          @visit_ok = true
          pf = R10K::Puppetfile.new(@root, @moduledir, @puppetfile)
          pf.accept(self)
          @visit_ok
        end

        private

        include R10K::Action::Visitor

        def visit_puppetfile(pf)
          pf.load!
          yield
          pf.purge!
        end

        def visit_module(mod)
          logger.info _("Updating module %{mod_path}") % {mod_path: mod.path}
          mod.sync(false) # Don't force sync for 'puppetfile install' RK-265
        end

        def allowed_initialize_opts
          super.merge(root: :self, puppetfile: :self, moduledir: :self)
        end
      end
    end
  end
end
