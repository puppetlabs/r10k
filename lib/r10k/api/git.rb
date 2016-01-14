require 'r10k/git'
require 'r10k/logging'

module R10K
  module API
    module Git
      extend R10K::Logging

      class CommandFailedError < StandardError; end

      module_function

      def reset(ref, opts={})
        provider.reset(ref, opts)
      end

      def clean(opts={})
        provider.clean(opts)
      end

      def rev_parse(rev, opts={})
        result = provider.rev_parse(rev, opts)

        if result.success?
          return result.stdout.strip
        else
          raise CommandFailedError.new(result.stderr)
        end
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

