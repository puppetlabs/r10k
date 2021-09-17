require 'r10k/util/setopts'
require 'r10k/logging'

module R10K
  module Action
    class Base

      include R10K::Util::Setopts
      include R10K::Logging

      attr_accessor :settings

      # @param opts [Hash] A hash of options defined in #allowed_initialized_opts
      #   and managed by the SetOps mixin within the Action::Base class.
      #   Corresponds to the CLI flags and options.
      # @param argv [Enumerable] Typically CRI::ArgumentList or Array. A list-like
      #   collection of the remaining arguments to the CLI invocation (after
      #   removing flags and options).
      # @param settings [Hash] A hash of configuration loaded from the relevant
      #   config (r10k.yaml).
      #
      # @note All arguments will be required in the next major version
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
        }
      end
    end
  end
end
