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

    def level=(val)
      level = parse_level val
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

  Configurator.custom_levels(*LOG_LEVELS)
  Logger.global.level = Log4r::ALL

  @level     = Log4r::WARN
  @formatter = default_formatter
  @outputter = default_outputter
end
