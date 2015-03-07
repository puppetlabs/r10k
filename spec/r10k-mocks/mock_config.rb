require 'r10k/deployment/config'

module R10K
  class Deployment
    class MockConfig
      def initialize(hash)
        @hash = hash
      end

      def configfile
        "/some/nonexistent/config_file"
      end

      # Perform a scan for key and check for both string and symbol keys
      def setting(key)
        keys = [key]
        case key
        when String
          keys << key.to_sym
        when Symbol
          keys << key.to_s
        end

        # Scan all possible keys to see if the config has a matching value
        keys.inject(nil) do |rv, k|
          v = @hash[k]
          break v unless v.nil?
        end
      end
    end
  end
end
