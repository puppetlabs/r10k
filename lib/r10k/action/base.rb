require 'r10k/util/setopts'
require 'r10k/logging'

module R10K
  module Action
    class Base

      include R10K::Logging
      include R10K::Util::Setopts

      def initialize(opts, argv)
        @opts = opts
        @argv = argv

        setopts(opts, allowed_initialize_opts)
      end

      private

      def allowed_initialize_opts
        {
          :config => true,
          :trace  => true,
        }
      end
    end
  end
end
