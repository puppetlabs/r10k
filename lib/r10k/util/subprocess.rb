require 'childprocess'
require 'r10k/logging'

module R10K
  module Util
    class Subprocess
      # Name shamelessly stolen from vagrant :3

      attr_accessor :raise_on_fail

      def initialize(args)
        @args = args
        @options = (args.last.is_a? Hash) ? args.pop : {}

        @raise_on_fail = false

      end

      def execute
        child_process = ChildProcess.build(*@args)

        stdout_r, stdout_w = IO.pipe
        stderr_r, stderr_w = IO.pipe

        child_process.io.stdout = stdout_w
        child_process.io.stderr = stderr_w

        child_process.start
        stdout_w.close
        stderr_w.close
        child_process.wait

        raise Exception if $zapped

        stdout = stdout_r.read
        stderr = stderr_r.read

        result = Result.new(@args.join(" "), stdout, stderr, child_process.exit_code)

        if @raise_on_fail and child_process.crashed?
          raise SubProcessError.new(:result => result)
        end

        result
      ensure
        Signal.trap('INT', 'DEFAULT')
      end

      private

      class Result
        attr_reader :cmd, :stdout, :stderr, :exit_code

        def initialize(cmd, stdout, stderr, exit_code)
          @cmd = cmd
          @stdout = stdout
          @stderr = stderr
          @exit_code = exit_code
        end

        # We're a hash now! Yay!
        def [](field)
          send(field)
        end
      end

      class SubProcessError < StandardError
        def initialize(message = nil, options = {})
          if message.is_a? String
            super(message)
          elsif message.is_a? Hash
            options = message
            message = nil
          end

          parse_options(options)
        end

        private

        def parse_options(options)
          if (result = options[:result])
            @result = result
          end
        end
      end
    end
  end
end
