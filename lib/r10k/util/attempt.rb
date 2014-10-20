require 'r10k/logging'
require 'r10k/util/setopts'
require 'colored'

module R10K
  module Util

    # Attempt a series of dependent nested tasks and cleanly handle errors.
    #
    # @api private
    class Attempt

      include R10K::Logging
      include R10K::Util::Setopts

      # @!attribute [r] status
      #   @return [Symbol] The status of this task
      attr_reader :status

      def initialize(initial, opts = {})
        @initial = initial
        @tries = []
        @status = :notrun
        setopts(opts, {:trace => :self})
      end

      # Run this attempt to completion.
      #
      # @todo determine the structure of the ret
      # @return [Object] The aggregate result of all work performed.
      def run
        @status = :running
        result = apply(@initial, @tries)
        @status = :ok if @status == :running
        result
      end

      # Add another action to take for this attempt
      #
      # @yieldparam [Object] The result of the previous action.
      # @yieldreturn [Object, Array<Object>, NilClass] The result of this action.
      #   If the value is an object, it will be passed to the next attempt. If
      #   the value is an Array then each element will be individually passed
      #   to the next try. If the value is false or nil then no further action
      #   will be taken.
      def try(&block)
        @tries << block
        self
      end

      def ok?
        @status == :ok
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
        @status = :failed
        logger.error e.message
        $stderr.puts e.backtrace.join("\n").red if @trace
        e
      end
    end
  end
end
