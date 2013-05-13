require 'r10k/logging'
require 'r10k/errors'

require 'systemu'

module R10K
module Execution
  include R10K::Logging

  # Execute a command and return stdout
  #
  # @params [String] cmd
  # @params [Hash] opts
  #
  # @option opts [String] :event An optional log event name. Defaults to cmd.
  #
  # @raise [R10K::ExecutionFailure] If the executed command exited with a
  #   nonzero exit code.
  #
  # @return [String] the stdout from the command
  def execute(cmd, opts = {})

    event = opts[:event] || cmd

    logger.debug1 "Execute: #{event.inspect}"

    status, stdout, stderr = systemu(cmd)

    logger.debug2 "[#{event}] STDOUT: #{stdout.chomp}" unless stdout.empty?
    logger.debug2 "[#{event}] STDERR: #{stderr.chomp}" unless stderr.empty?

    unless status == 0
      msg = "#{cmd.inspect} returned with non-zero exit value #{status.exitstatus}"
      e = R10K::ExecutionFailure.new(msg)
      e.exit_code = status
      e.stdout    = stdout
      e.stderr    = stderr
      raise e
    end
    stdout
  end
end
end
