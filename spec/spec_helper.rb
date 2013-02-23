require 'mocha'

PROJECT_ROOT = File.expand_path('..', File.dirname(__FILE__))

RSpec.configure do |config|
  config.mock_with :mocha
end
