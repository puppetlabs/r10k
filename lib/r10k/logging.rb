require 'r10k'

require 'log4r'
require 'log4r/configurator'

module R10K::Logging

  include Log4r

  LOG_LEVELS = %w{DEBUG2 DEBUG1 DEBUG INFO NOTICE WARN ERROR FATAL}

  def logger_name
    self.class.to_s
  end

  def logger
    unless @logger
      @logger = Log4r::Logger.new(self.logger_name)
      @logger.add R10K::Logging.outputter
    end
    @logger
  end

  class << self
    include Log4r

    def levels
      @levels ||= LOG_LEVELS.each.inject({}) do |levels, k|
        levels[k] = Log4r.const_get(k)
        levels
      end
    end

    def parse_level(val)
      begin
        Integer(val)
      rescue
        levels[val.upcase]
      end
    end

    def included(klass)
      unless @log4r_loaded
        Configurator.custom_levels(*LOG_LEVELS)
        Logger.global.level = Log4r::ALL
        @log4r_loaded = true
      end
    end

    def level
      @level || Log4r::WARN # Default level is WARN
    end

    def level=(val)
      level = parse_level val
      raise "Invalid log level: #{val}" unless level
      outputter.level = level
      @level = level
    end

    def formatter
      @formatter ||= Log4r::PatternFormatter.new(:pattern => '[%C - %l] %m')
    end

    def outputter
      @outputter ||= Log4r::StderrOutputter.new('console',
        :level => self.level,
        :formatter => formatter
       )
    end
  end
end
