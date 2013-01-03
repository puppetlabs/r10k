require 'r10k/action'
require 'middleware'

module R10K::Action::Module

  class R10K::Action::Module::Deploy
    # Middleware to deploy a module

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

      puts "Deploying #{@mod.full_path}"
      @mod.sync! :update_cache => @env[:update_cache]

      @app.call(@env)
    rescue RuntimeError => e
      $stderr.puts "Could not synchronize #{@mod.full_path}: #{e}"
      $stderr.puts e.backtrace.join("\n").red if @env[:trace]
      @app.call(@env)
    end
  end
end
