require 'r10k/action'
require 'r10k/errors'
require 'r10k/logging'

require 'middleware'

module R10K::Action::Module

  class R10K::Action::Module::Deploy
    # Middleware to deploy a module

    include R10K::Logging

    # @param [Object] app The next application in the middlware stack
    # @param [R10K::Module] mod The module to deploy
    def initialize(app, mod)
      @app, @mod = app, mod
    end

    # @param [Hash] env
    #
    # @option env [true, false] :update_cache
    def call(env)
      @env = env

      logger.notice "Deploying module #{@mod.name}"
      @mod.sync! :update_cache => @env[:update_cache]

      @app.call(@env)
    rescue R10K::ExecutionFailure => e
      logger.error "Could not synchronize #{@mod.full_path}: #{e}".red

      if @env[:trace]
        $stderr.puts "stdout: #{e.stdout}"
        $stderr.puts "stderr: #{e.stderr}"
        $stderr.puts "Stacktrace\n---\n#{e.backtrace.join("\n")}".red
      end
      @app.call(@env)
    end
  end
end
