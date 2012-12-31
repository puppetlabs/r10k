require 'r10k'
require 'r10k/action/module/deploy'
require 'middleware'

module R10K::Action
end

module R10K::Action::Module
end

class R10K::Action::Module::Deploy
  def initialize(app, mod)
    @app, @mod = app, mod
  end

  #
  # @param [Hash] env
  #
  # @option env [true, false] :update_cache
  def call(env)
    @env = env

    puts "Deploying #{@mod.full_path}"
    @mod.sync! :update_cache => @env[:update_cache]

    @app.call(@env)
  end
end
