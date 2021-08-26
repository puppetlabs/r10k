require 'r10k/source'
require 'r10k-mocks/mock_env'

class R10K::Source::Mock < R10K::Source::Base
  R10K::Source.register(:mock, self)

  def environments
    if @_environments.nil?
      corrected_environment_names = @options[:environments].map do |env|
        R10K::Environment::Name.new(env, :prefix => @prefix, :invalid => 'correct_and_warn')
      end
      @_environments = corrected_environment_names.map { |env| R10K::Environment::Mock.new(env.name, @basedir, env.dirname, { overrides: @options[:overrides] }) }
    end

    @_environments
  end
end
