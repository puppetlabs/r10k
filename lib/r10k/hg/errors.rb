require 'r10k/errors'

module R10K
  module Hg

    class HgError < R10K::Error
      attr_reader :hg_dir

      def initialize(mesg, options = {})
        super
        hg_dir = @options[:hg_dir]
      end

      def message
        msg = super
        if @hg_dir
          msg << " at #{@hg_dir}"
        end
        msg
      end
    end


    class UnknownRevisionError < HgError

      attr_reader :rev

      def initialize(mesg, options = {})
        super
        @rev = @options[:rev]
      end
    end
  end
end
