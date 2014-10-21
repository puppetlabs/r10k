require 'r10k/errors'

module R10K
  module Errors
    module Formatting
      module_function

      # Format this exception for displaying to the user
      #
      # @param exc [Exception] The exception to format
      # @param with_backtrace [true, false] Whether the backtrace should be
      #   included with this exception
      # @return [String]
      def format_exception(exc, with_backtrace = false)
        lines = []
        lines << exc.message
        if with_backtrace
          lines.concat(exc.backtrace)
        end
        if exc.respond_to?(:original) && exc.original
          lines << "Original:"
          lines<< format_exception(exc.original, with_backtrace)
        end
        lines.join("\n")
      end
    end
  end
end
