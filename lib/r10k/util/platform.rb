require 'rbconfig'

module R10K
  module Util
    module Platform
      FIPS_FILE = "/proc/sys/crypto/fips_enabled"

      def self.platform
        # Test JRuby first to handle JRuby on Windows as well.
        if self.jruby?
          :jruby
        elsif self.windows?
          :windows
        else
          :posix
        end
      end

      # We currently only suport FIPS mode on redhat 7, where it is
      # toggled via a file.
      def self.fips?
        if File.exist?(FIPS_FILE)
          File.read(FIPS_FILE).chomp == "1"
        else
          false
        end
      end

      def self.windows?
        RbConfig::CONFIG['host_os'] =~ /mswin|win32|dos|mingw|cygwin/i
      end

      def self.jruby?
        RUBY_PLATFORM == "java"
      end

      def self.posix?
        !windows? && !jruby?
      end
    end
  end
end
