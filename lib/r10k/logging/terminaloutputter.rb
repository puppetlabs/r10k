require 'colored'
require 'r10k/logging'
require 'log4r/outputter/iooutputter'

module R10K
  module Logging
    class TerminalOutputter < Log4r::IOOutputter

      COLORS = [
        nil,
        :cyan,
        :cyan,
        :green,
        nil,
        nil,
        :yellow,
        :red,
        :red,
      ]

      attr_accessor :use_color

      private

      def format(logevent)
        string = super
        if @use_color
          color = COLORS[logevent.level]
          color ? string.send(color) : string
        else
          string
        end
      end
    end
  end
end
