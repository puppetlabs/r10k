require 'r10k/git'
require 'r10k/logging'

module R10K
  module API
    module Git
      extend R10K::Logging

      module_function

      def reset(ref, opts={})
        provider.reset(ref, opts)
      end

      def clean(opts={})
        provider.clean(opts)
      end

      def rev_parse(rev, opts={})
        provider.rev_parse(rev, opts)
      end

      private

      def self.provider
        R10K::Git.provider
      end
      private_class_method :provider
    end
  end
end

