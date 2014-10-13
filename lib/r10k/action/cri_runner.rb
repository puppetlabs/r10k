require 'r10k/action/runner'

module R10K
  module Action
    class CriRunner

      def self.wrap(klass)
        new(klass)
      end

      def initialize(klass)
        @klass = klass
      end

      def new(opts, args, _cmd)
        # @todo swap args order for consistency
        R10K::Action::Runner.new(args, opts, @klass)
      end
    end
  end
end
