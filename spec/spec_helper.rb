PROJECT_ROOT = File.expand_path('..', File.dirname(__FILE__))

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    libdir = File.join(PROJECT_ROOT, 'lib')
    add_filter do |src|
      !src.filename.match(%r[\A#{libdir}])
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
require 'matchers/match_realpath'
require 'r10k-mocks'

# Add a negated version of the change matcher.
RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.configure do |config|
  config.before(:all) do
    Log4r::Logger.global.level = Log4r::OFF
  end
end

shared_context 'fail on execution' do
  before do
    allow_any_instance_of(described_class).to receive(:execute).and_raise "Tests should never invoke system calls"
    allow_any_instance_of(R10K::Util::Subprocess).to receive(:execute).and_raise "Tests should never invoke system calls"
  end
end
