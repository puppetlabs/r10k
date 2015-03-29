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

    # Convert the input to a valid Log4r log level
    #
    # @param input [String, TrueClass] The level to parse. If TrueClass then
    #   Log4r::INFO will be returned (indicating a generic raised verbosity),
    #   if a string it will be parsed either as a numeric value or a textual
    #   log level.
    # @api private
    # @return [Integer, NilClass] The numeric log level, or nil if the log
    #   level is invalid.
    def parse_level(input)
      case input
      when TrueClass
        Log4r::INFO
      when /\A\d+\Z/
        Integer(input)
      when String
        const_name = input.upcase
        if LOG_LEVELS.include?(const_name)
          begin
            Log4r.const_get(const_name.to_sym)
          rescue NameError
          end
        end
      end
    end

    def level=(val)
      level = parse_level(val)
      if level.nil?
        raise ArgumentError, "Invalid log level '#{val}'. Valid levels are #{LOG_LEVELS.map(&:downcase).inspect}"
      end
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
