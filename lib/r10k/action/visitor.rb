require 'r10k/errors/formatting'

module R10K
  module Action
    # Implement the Visitor pattern via pseudo double dispatch.
    #
    # Visitor classes must implement #visit_type methods for each type that may
    # be visited. If the visitor should descend into child objects the #visit_
    # method should yield to the passed block.
    #
    # Visitor classes must implement #logger so that error messages can be logged.
    #
    # @api private
    module Visitor

      # Dispatch to the type specific visitor method
      #
      # @param type [Symbol] The object type to dispatch for
      # @param other [Object] The actual object to pass to the visitor method
      # @param block [Proc] The block that the called visitor method may yield
      #   to in case recursion is desired.
      # @return [void]
      def visit(type, other, &block)
        send("visit_#{type}", other, &block)
      rescue => e
        logger.error R10K::Errors::Formatting.format_exception(e, @trace)
        @visit_ok = false
      end
    end
  end
end
