require 'r10k/logging'
require 'log4r/outputter/syslogoutputter'

module R10K
  module Logging
    class SyslogOutputter < Log4r::SyslogOutputter
      SYSLOG_FACILITY_MAP = {
        "CRON"   => LOG_CRON,
        "DAEMON" => LOG_DAEMON,
        "USER"   => LOG_USER,
        "LOCAL0" => LOG_LOCAL0,
        "LOCAL1" => LOG_LOCAL1,
        "LOCAL2" => LOG_LOCAL2,
        "LOCAL3" => LOG_LOCAL3,
        "LOCAL4" => LOG_LOCAL4,
        "LOCAL5" => LOG_LOCAL5,
        "LOCAL6" => LOG_LOCAL6,
        "LOCAL7" => LOG_LOCAL7,
      }

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

      def initialize(_name, hash={})
        super(_name, hash)
        map_levels_by_name_to_syslog(SYSLOG_R10K_MAP)
      end

      def facility=(val)
        if val.is_a? String
          facility = SYSLOG_FACILITY_MAP[val.upcase].to_i
        else
          facility = val
        end

        @syslog.reopen(@syslog.ident, @syslog.options, facility)
      end
    end
  end
end
