require 'r10k'
require 'r10k/action/module/deploy'
require 'middleware'

module R10K::Action
end

module R10K::Action::Environment
end

class R10K::Action::Environment::Deploy
  def initialize(app, root)
    @app, @root = app, root
  end

  #
  # @param [Hash] env
  #
  # @option env [true, false] :update_cache
  # @option env [true, false] :recurse
  def call(env)
    @env = env

    puts "Deploying #{@root.full_path}"
    FileUtils.mkdir_p @root.full_path
    @root.sync! :update_cache => @env[:update_cache]

    if @env[:recurse]
      # Build a new middleware chain and run it
      stack = Middleware::Builder.new
      @root.modules.each { |mod| stack.use R10K::Action::Module::Deploy, mod }
      stack.call(@env)
    end

    @app.call(@env)
  end
end
