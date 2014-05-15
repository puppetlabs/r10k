require 'cri/command_dsl'

module Cri
  class CommandDSL
    include R10K::Logging

    def logger
      unless @logger
        @logger = Log4r::Logger.new(@command.name)
        @logger.add R10K::Logging.outputter
      end
      @logger
    end
  end
end
