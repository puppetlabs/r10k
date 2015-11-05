require 'rbconfig'

module R10K
  module Util
    module Platform
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
