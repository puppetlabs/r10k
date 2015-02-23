PROJECT_ROOT = File.expand_path('..', File.dirname(__FILE__))

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter do |src|
      !src.filename.match(%r[lib/r10k])
    end

    %w[Deployment Source Environment Module Git SVN Action Util].each do |group|
      add_group group, "lib/r10k/#{group.downcase}"
    end
  end
end

require 'r10k'

Dir.glob(File.expand_path('spec/shared-examples/**/*.rb', PROJECT_ROOT)).each { |file| require file }

require 'shared-contexts/git-fixtures'
require 'matchers/exit_with'
require 'r10k-mocks'


require 'vcr'
VCR.configure do |vcr|
  vcr.cassette_library_dir = File.expand_path('spec/fixtures/vcr/cassettes', PROJECT_ROOT)
  # VCR 2.9.3 uses a Faraday constant that was deprecated in Faraday 0.9.0,
  # and as such triggers a warning on the part of Faraday during the following
  # hooking step. It's known and there's nothing that can be done until VCR
  # 2.9.4 comes out.
  vcr.hook_into :faraday
  vcr.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.before(:all) do
    Log4r::Logger.global.level = 10
  end
end

shared_context 'fail on execution' do
  before do
    allow_any_instance_of(described_class).to receive(:execute).and_raise "Tests should never invoke system calls"
    allow_any_instance_of(R10K::Util::Subprocess).to receive(:execute).and_raise "Tests should never invoke system calls"
  end
end
