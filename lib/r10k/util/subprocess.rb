require 'r10k/errors'
require 'r10k/util/platform'

module R10K
  module Util

    # The subprocess namespace implements an interface similar to childprocess.
    # The interface has been simplified to make it easier to use and does not
    # depend on native code.
    #
    # @api private
    class Subprocess

      require 'r10k/util/subprocess/runner'
      require 'r10k/util/subprocess/io'
      require 'r10k/util/subprocess/result'

      require 'r10k/util/subprocess/posix'
      require 'r10k/util/subprocess/windows'

      # @return [Class < R10K::Util::Subprocess::Runner]
      def self.runner
        if R10K::Util::Platform.windows?
          R10K::Util::Subprocess::Windows::Runner
        else
          R10K::Util::Subprocess::POSIX::Runner
        end
      end

      include R10K::Logging

      # @!attribute [r] argv
      #   @return [Array<String>] The command to be executed
      attr_reader :argv

      # @!attribute [rw] raise_on_fail
      #   Determine whether #execute raises an error when the command exits
      #   with a non-zero exit status.
      #   @return [true, false]
      attr_accessor :raise_on_fail

      # @!attribute [rw] cwd
      #   @return [String] The directory to be used as the cwd when executing
      #     the command.
      attr_accessor :cwd

      # @!attribute [w] logger
      #   Allow calling processes to take ownership of execution logs by passing
      #   their own logger to the command being executed.
      attr_writer :logger

      # Prepare the subprocess invocation.
      #
      # @param argv [Array<String>] The argument vector to execute
      def initialize(argv)
        @argv = argv

        @raise_on_fail = false
      end

      # Execute the given command and return the result of evaluation.
      #
      # @api public
      # @raise [R10K::Util::Subprocess::SubprocessError] if raise_on_fail is
      #   true and the command exited with a non-zero status.
      # @return [R10K::Util::Subprocess::Result]
      def execute
        subprocess = self.class.runner.new(@argv)
        subprocess.cwd = @cwd if @cwd

        logmsg = "Execute: #{@argv.join(' ')}"
        logmsg << "(cwd: #{@cwd})" if @cwd
        logger.debug1 logmsg

        subprocess.run

        result = subprocess.result

        logger.debug2 "[#{result.cmd}] STDOUT: #{result.stdout.chomp}" unless result.stdout.empty?
        logger.debug2 "[#{result.cmd}] STDERR: #{result.stderr.chomp}" unless result.stderr.empty?

        if @raise_on_fail and subprocess.crashed?
          raise SubprocessError.new(:result => result)
        end

        result
      end

      class SubprocessError < R10KError

        # !@attribute [r] result
        #   @return [R10K::Util::Subprocess::Result]
        attr_reader :result

        def initialize(mesg = nil, options = {})
          super
          @result = @options[:result]
        end

        def to_s
          if @mesg
            @mesg
          else
            "Command #{@result.cmd} exited with #{@result.exit_code}: #{@result.stderr}"
          end
        end
      end
    end
  end
end
