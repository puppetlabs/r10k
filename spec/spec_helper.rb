require 'r10k'
require 'mocha'

PROJECT_ROOT = File.expand_path('..', File.dirname(__FILE__))

RSpec.configure do |config|
  config.mock_with :mocha

  # Filter out integration tests by default
  #
  # To run integration tests, run `rspec --tag integration`
  config.filter_run_excluding :integration => true
end
