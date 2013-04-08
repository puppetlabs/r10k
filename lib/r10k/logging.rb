require 'r10k'

require 'log4r'
require 'log4r/configurator'

module R10K::Logging

  include Log4r

  def logger_name
    self.class.name
  end

  def logger
    unless @logger
      @logger = Log4r::Logger.new(logger_name)
      @logger.add R10K::Logging.outputter
    end
    @logger
  end

  class << self
    include Log4r

    def included(klass)
      unless @log4r_loaded
        Configurator.custom_levels(*%w{DEBUG2 DEBUG1 DEBUG INFO NOTICE WARN ERROR FATAL})
        Logger.global.level = Log4r::ALL
        @log4r_loaded = true
      end
    end

    def level
      @level || Log4r::WARN # Default level is WARN
    end

    def level=(val)
      outputter.level = val
      @level = val
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
