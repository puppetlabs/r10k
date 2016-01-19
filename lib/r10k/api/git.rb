require 'r10k/git'
require 'r10k/logging'

module R10K
  module API
    module Git
      extend R10K::Logging

      module_function

      # TODO: enforce required opts at this level?

      def reset(ref, opts={})
        provider.reset(ref, opts)
      end

      def clean(opts={})
        provider.clean(opts)
      end

      def rev_parse(rev, opts={})
        provider.rev_parse(rev, opts)
      end

      def fetch(remote, opts={})
        provider.fetch(remote, opts)
      end

      def clone(remote, local, opts={})
        provider.clone(remote, local, opts)
      end

      def blob_at(rev, path, opts={})
        provider.blob_at(rev, path, opts)
      end

      def branch_list(opts={})
        provider.branch_list(opts)
      end

      private

      def self.provider
        if R10K::Features.available?(:rjgit)
          R10K::Git.provider = :rjgit
        end

        R10K::Git.provider
      end
      private_class_method :provider
    end
  end
end
