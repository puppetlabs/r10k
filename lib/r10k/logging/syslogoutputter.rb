require 'r10k/logging'
require 'log4r/outputter/syslogoutputter'

module R10K
  module Logging
    class SyslogOutputter < Log4r::SyslogOutputter
      SYSLOG_R10K_MAP = {
        "DEBUG2" => "DEBUG",
        "DEBUG1" => "DEBUG",
        "DEBUG"  => "DEBUG",
        "INFO"   => "INFO",
        "NOTICE" => "NOTICE",
        "WARN"   => "WARN",
        "ERROR"  => "ERROR",
        "FATAL"  => "FATAL",
      }

      @levels_map = SYSLOG_R10K_MAP
    end
  end
end
