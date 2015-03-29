require 'r10k'

require 'log4r'
require 'log4r/configurator'

module R10K::Logging

  LOG_LEVELS = %w{DEBUG2 DEBUG1 DEBUG INFO NOTICE WARN ERROR FATAL}

  def logger_name
    self.class.to_s
  end

  def logger
    if @logger.nil?
      name = logger_name
      if Log4r::Logger[name]
        @logger = Log4r::Logger[name]
      else
        @logger = Log4r::Logger.new(name)
        @logger.add(R10K::Logging.outputter)
      end
    end
    @logger
  end

  class << self
    def parse_level(string)
      Integer(string)
    rescue
      const = string.upcase.to_sym
      begin
        Log4r.const_get(const)
      rescue NameError
      end
    end

    def level=(val)
      level = parse_level(val)
      raise "Invalid log level: #{val}" unless level
      outputter.level = level
      @level = level
    end

    # @!attribute [r] level
    #   @return [Integer] The current log level. Lower numbers correspond
    #     to more verbose log levels.
    attr_reader :level

    # @!attribute [r] formatter
    #   @api private
    #   @return [Log4r::Formatter]
    attr_reader :formatter

    # @!attribute [r] outputter
    #   @api private
    #   @return [Log4r::Outputter]
    attr_reader :outputter

    def default_formatter
      Log4r::PatternFormatter.new(:pattern => '%l\t -> %m')
    end

    def default_outputter
      Log4r::StderrOutputter.new('console', :level => self.level, :formatter => formatter)
    end
  end

  Log4r::Configurator.custom_levels(*LOG_LEVELS)
  Log4r::Logger.global.level = Log4r::ALL

  @level     = Log4r::WARN
  @formatter = default_formatter
  @outputter = default_outputter
end
