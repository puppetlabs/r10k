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
          pf = R10K::Puppetfile.new(@root, @moduledir, @puppetfile, nil , @force)
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
          @force ||= false
          logger.info _("Updating module %{mod_path}") % {mod_path: mod.printpath}

          if mod.respond_to?(:desired_ref) && mod.desired_ref == :control_branch
            logger.warn _("Cannot track control repo branch for content '%{name}' when not part of a 'deploy' action, will use default if available." % {name: mod.name})
          end

          mod.sync(force: @force)
        end

        def allowed_initialize_opts
          super.merge(root: :self, puppetfile: :self, moduledir: :self, force: :self )
        end
      end
    end
  end
end
