require 'r10k/puppetfile'
require 'r10k/util/setopts'
require 'r10k/errors/formatting'
require 'r10k/logging'

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
            :parallel   => :self
          })
        end

        def call
          pf = R10K::Puppetfile.new(@root, @moduledir, @path)
          pf.accept(self, @parallel.to_i)
          @ok
        end

        def visit(type, other, &block)
          send("visit_#{type}", other, &block)
        rescue => e
          logger.error R10K::Errors::Formatting.format_exception(e, @trace)
          @ok = false
        end

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
