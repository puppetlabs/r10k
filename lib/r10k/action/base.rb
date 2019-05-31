require 'r10k/util/setopts'
require 'r10k/logging'

module R10K
  module Action
    class Base

      include R10K::Logging
      include R10K::Util::Setopts

      attr_accessor :settings

      def initialize(opts, argv, settings = {})
        @opts = opts
        @argv = argv
        @settings = settings

        setopts(opts, allowed_initialize_opts)
      end

      private

      def allowed_initialize_opts
        {
          :config => true,
          :trace  => true,
          :help => true,
        }
      end
    end
  end
end
