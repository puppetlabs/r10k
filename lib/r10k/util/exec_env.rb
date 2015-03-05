module R10K
  module Util

    # Utility methods for dealing with environment variables
    module ExecEnv
      module_function

      # Swap out all environment settings
      #
      # @param env [Hash] The new environment to use
      # @return [void]
      def reset(env)
        env.each_pair do |key, value|
          ENV[key] = value
        end

        (ENV.keys - env.keys).each do |key|
          ENV.delete(key)
        end
      end

      # Add the specified settings to the env for the supplied block
      #
      # @param env [Hash] The values to add to the environment
      # @param block [Proc] The code to call with the modified environnment
      # @return [void]
      def withenv(env, &block)
        original = ENV.to_hash
        reset(original.merge(env))
        block.call
      ensure
        reset(original)
      end
    end
  end
end
