require 'r10k/logging'
require 'r10k/util/setopts'
require 'colored'

module R10K
  module Util
    class Attempt

      include R10K::Logging
      include R10K::Util::Setopts

      def initialize(value, opts = {})
        @value = value
        @tries = []

        setopts(opts, {:trace => :self})
      end

      def run
        apply(@value, @tries)
      end

      def try(&block)
        @tries << block
        self
      end

      private

      def apply(input, tries)
        return input if tries.empty?

        case input
        when Array
          apply_all(input, tries)
        when NilClass, FalseClass
          input
        else
          apply_one(input, tries)
        end
      end

      def apply_all(values, tries)
        values.map { |v| apply_one(v, tries) }
      end

      def apply_one(value, tries)
        apply(tries.first.call(value), tries.drop(1))
      rescue => e
        logger.error e.message
        $stderr.puts e.backtrace.join("\n").red if @trace
        e
      end
    end
  end
end
