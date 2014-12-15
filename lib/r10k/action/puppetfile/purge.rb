require 'r10k/puppetfile'
require 'r10k/util/setopts'
require 'r10k/errors/formatting'
require 'r10k/logging'

module R10K
  module Action
    module Puppetfile
      class Purge
        include R10K::Logging
        include R10K::Util::Setopts

        def initialize(opts, argv)
          @opts = opts
          @argv = argv

          setopts(opts, {
            :root       => :self,
            :moduledir  => :self,
            :puppetfile => :path,
            :trace      => :self,
          })
        end

        def call
          pf = R10K::Puppetfile.new(@root, @moduledir, @path)
          pf.load!
          pf.purge!
          true
        rescue => e
          logger.error R10K::Errors::Formatting.format_exception(e, @trace)
          false
        end
      end
    end
  end
end
