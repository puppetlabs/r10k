require 'r10k'

require 'log4r'

module R10K::Logging

  def logger
    unless @logger
      @logger = Log4r::Logger.new(self.class.name)
      @logger.add R10K::Logging.outputter
    end
    @logger
  end

  class << self
    def formatter
      @formatter ||= Log4r::PatternFormatter.new(:pattern => '[%C - %l] %m')
    end

    def outputter
      @outputter ||= Log4r::StderrOutputter.new('console',
        :level => Log4r::ALL,
        :formatter => formatter
       )
    end
  end
end
