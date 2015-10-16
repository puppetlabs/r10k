require 'r10k/logging'

module R10K
  class Deployment

    # @api private
    module WriteLock
      include R10K::Logging

      # @param config [Hash] The r10k config hash
      #
      # @raise [SystemExit] if the deploy write_lock setting has been set
      def check_write_lock!(config)
        write_lock = config.fetch(:deploy, {})[:write_lock]
        if write_lock
          logger.fatal("Making changes to deployed environments has been administratively disabled.")
          logger.fatal("Reason: #{write_lock}")
          exit(16)
        end
      end
    end
  end
end
