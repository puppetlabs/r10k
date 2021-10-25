require 'r10k'
require 'forwardable'

require 'log4r'
require 'log4r/configurator'
require 'r10k/logging/terminaloutputter'

module R10K::Logging

  LOG_LEVELS = %w{DEBUG2 DEBUG1 DEBUG INFO NOTICE WARN ERROR FATAL}
  SYSLOG_LEVELS_MAP = {
    'DEBUG2' => 'DEBUG',
    'DEBUG1' => 'DEBUG',
    'DEBUG' => 'DEBUG',
    'INFO' => 'INFO',
    'NOTICE' => 'INFO',
    'WARN' => 'WARN',
    'ERROR' => 'ERROR',
    'FATAL' => 'FATAL',
  }.freeze

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
        R10K::Logging.outputters.each do |output|
          @logger.add(output)
        end
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
        raise ArgumentError, _("Invalid log level '%{val}'. Valid levels are %{log_levels}") % {val: val, log_levels: LOG_LEVELS.map(&:downcase).inspect}
      end
      outputter.level = level unless @disable_default_stderr
      @level = level

      if level < Log4r::INFO
        outputter.formatter = debug_formatter
      else
        outputter.formatter = default_formatter
      end
    end

    def disable_default_stderr=(val)
      @disable_default_stderr = val
      outputter.level = val ? Log4r::OFF : @level
    end

    def add_outputters(outputs)
      outputs.each do |output|
        type = output.fetch(:type)
        # Support specifying both short as well as full names
        type = type.to_s[0..-10] if type.to_s.downcase.end_with? 'outputter'

        name = output.fetch(:name, 'r10k')
        if output[:level]
          level = parse_level(output[:level])
          if level.nil?
            raise ArgumentError, _("Invalid log level '%{val}'. Valid levels are %{log_levels}") % { val: output[:level], log_levels: LOG_LEVELS.map(&:downcase).inspect }
          end
        else
          level = self.level
        end
        only_at = output[:only_at]
        only_at&.map! do |val|
          lv = parse_level(val)
          if lv.nil?
            raise ArgumentError, _("Invalid log level '%{val}'. Valid levels are %{log_levels}") % { val: val, log_levels: LOG_LEVELS.map(&:downcase).inspect }
          end

          lv
        end
        parameters = output.fetch(:parameters, {}).merge({ level: level })

        begin
          # Try to load the outputter file if possible
          require "log4r/outputter/#{type.to_s.downcase}outputter"
        rescue LoadError
          false
        end
        outputtertype = Log4r.constants
                             .select { |klass| klass.to_s.end_with? 'Outputter' }
                             .find { |klass| klass.to_s.downcase == "#{type.to_s.downcase}outputter" }
        raise ArgumentError, "Unable to find a #{output[:type]} outputter." unless outputtertype

        outputter = Log4r.const_get(outputtertype).new(name, parameters)
        outputter.only_at(*only_at) if only_at
        # Handle log4r's syslog mapping correctly
        outputter.map_levels_by_name_to_syslog(SYSLOG_LEVELS_MAP) if outputter.respond_to? :map_levels_by_name_to_syslog

        @outputters << outputter
        Log4r::Logger.global.add outputter
      end
    end

    extend Forwardable
    def_delegators :@outputter, :use_color, :use_color=

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

    # @!attribute [r] outputters
    #   @api private
    #   @return [Array[Log4r::Outputter]]
    attr_reader :outputters

    # @!attribute [r] disable_default_stderr
    #   @api private
    #   @return [Boolean]
    attr_reader :disable_default_stderr

    def default_formatter
      Log4r::PatternFormatter.new(:pattern => '%l\t -> %m')
    end

    def debug_formatter
      Log4r::PatternFormatter.new(:pattern => '[%d - %l] %m')
    end

    def default_outputter
      R10K::Logging::TerminalOutputter.new('terminal', $stderr, :level => self.level, :formatter => formatter)
    end
  end

  Log4r::Configurator.custom_levels(*LOG_LEVELS)
  Log4r::Logger.global.level = Log4r::ALL

  @level     = Log4r::WARN
  @formatter = default_formatter
  @outputter = default_outputter
  @outputters = []
  @disable_default_stderr = false
end
