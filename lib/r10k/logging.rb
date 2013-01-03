require 'r10k'

require 'log4r'
require 'log4r/base'
require 'log4r/logger'

module R10K::Logging

  def logger
    unless @logger
      @logger = Log4r::Logger.new(self.class.name)
      @logger.add R10K::Logging.outputter
    end
    @logger
  end

  class << self

    Log4r::Logger.global.level = Log4r::ALL

    def level
      @level || 3 # Default level is WARN
    end

    def level=(val)
      @level = val
      outputter.level = @level
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
