require 'r10k/puppetfile'
require 'r10k/util/setopts'
require 'r10k/errors/formatting'
require 'r10k/logging'
require 'r10k/action/visitor'

module R10K
  module Action
    module Puppetfile
      class Install
        include R10K::Logging
        include R10K::Util::Setopts

        def initialize(opts, argv)
          @opts = opts
          @argv = argv

          @ok = true

          setopts(opts, {
            :root       => :self,
            :moduledir  => :self,
            :puppetfile => :path,
            :trace      => :self,
          })
        end

        def call
          @visit_ok = true
          pf = R10K::Puppetfile.new(@root, @moduledir, @path)
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
          logger.info "Updating module #{mod.path}"
          mod.sync
        end
      end
    end
  end
end
