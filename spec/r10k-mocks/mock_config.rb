require 'r10k/deployment/config'

module R10K
  class Deployment
    class MockConfig

      attr_accessor :hash

      def initialize(hash)
        @hash = hash.merge(deploy: {})
      end

      def configfile
        "/some/nonexistent/config_file"
      end

      # Perform a scan for key and check for both string and symbol keys
      def setting(key)
        @hash[key]
      end

      alias [] setting

      def settings
        @hash
      end
    end
  end
end
