require 'r10k/logging'
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
      require 'r10k/util/subprocess/result'
      require 'r10k/util/subprocess/subprocess_error'

      # @return [Class < R10K::Util::Subprocess::Runner]
      def self.runner
        if R10K::Util::Platform.windows?
          R10K::Util::Subprocess::Runner::Windows
        elsif R10K::Util::Platform.jruby?
          R10K::Util::Subprocess::Runner::JRuby
        else
          R10K::Util::Subprocess::Runner::POSIX
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

        logmsg = _("Starting process: %{args}") % {args: @argv.inspect}
        logmsg << "(cwd: #{@cwd})" if @cwd
        logger.debug2(logmsg)

        result = subprocess.run
        logger.debug2(_("Finished process:\n%{result}") % {result: result.format})

        if @raise_on_fail && result.failed?
          raise SubprocessError.new(_("Command exited with non-zero exit code"), :result => result)
        end

        result
      end
    end
  end
end
