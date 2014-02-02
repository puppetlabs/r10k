require 'r10k'

require 'shared-examples/git-ref'

PROJECT_ROOT = File.expand_path('..', File.dirname(__FILE__))

require 'vcr'
VCR.configure do |vcr|
  vcr.cassette_library_dir = File.expand_path('spec/fixtures/vcr/cassettes', PROJECT_ROOT)
  vcr.hook_into :faraday
  vcr.configure_rspec_metadata!
end

RSpec.configure do |config|
  # Filter out integration tests by default
  #
  # To run integration tests, run `rspec --tag integration`
  config.filter_run_excluding :integration => true
end

shared_context 'stub logging' do
  before do
    log = double('stub logger').as_null_object
    allow_any_instance_of(described_class).to receive(:logger).and_return log
  end
end

shared_context 'fail on execution' do
  before do
    allow_any_instance_of(described_class).to receive(:execute).and_raise "Tests should never invoke system calls"
    allow_any_instance_of(R10K::Util::Subprocess).to receive(:execute).and_raise "Tests should never invoke system calls"
  end
end
