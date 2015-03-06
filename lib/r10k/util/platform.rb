require 'rbconfig'

module R10K
  module Util
    module Platform
      def self.platform
        if self.windows?
          :windows
        else
          :posix
        end
      end

      def self.windows?
        RbConfig::CONFIG['host_os'] =~ /mswin|win32|dos|mingw|cygwin/i
      end

      def self.java?
        RbConfig::CONFIG['sitearch'] == 'java'
      end

      def self.posix?
        !(windows? || java?)
      end
    end
  end
end
