module R10K
  module Action
    module Deploy
      module DeployHelpers

        # Ensure that a config file has been found (and presumably loaded) and exit
        # with a helpful error if it hasn't.
        #
        # @raise [SystemExit] If no config file was loaded
        def expect_config!
          if @config.nil?
            logger.fatal(_("No configuration file given, no config file found in current directory, and no global config present"))
            exit(8)
          end
        end

        # Check to see if the deploy write_lock setting has been set, and log the lock message
        # and exit if it has been set.
        #
        # @param config [Hash] The r10k config hash
        #
        # @raise [SystemExit] if the deploy write_lock setting has been set
        def check_write_lock!(config)
          write_lock = config.fetch(:deploy, {})[:write_lock]
          if write_lock
            logger.fatal(_("Making changes to deployed environments has been administratively disabled."))
            logger.fatal(_("Reason: %{write_lock}") % {write_lock: write_lock})
            exit(16)
          end
        end
      end
    end
  end
end
