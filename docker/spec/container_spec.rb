require 'rspec'
require 'fileutils'
require 'pupperware/spec_helper'
include Pupperware::SpecHelpers

SPEC_DIRECTORY = File.dirname(__FILE__)

def r10k(command)
  docker_compose("exec -T r10k r10k #{command} --puppetfile /test/Puppetfile")
end

describe 'r10k container' do
  before(:all) do
    ENV['R10K_IMAGE'] = require_test_image()
    teardown_cluster()
    docker_compose_up()
  end

  after(:all) do
    emit_logs()
    teardown_cluster()
    FileUtils.rm_rf(File.join(SPEC_DIRECTORY, 'fixtures', 'modules'))
  end

  it 'should validate the Puppetfile' do
    result = r10k('puppetfile check')
    expect(result[:status].exitstatus).to equal(0)
    expect(result[:stderr].chomp).to eq('Syntax OK')
  end

  it 'should install the Puppetfile' do
    result = r10k('puppetfile install')
    expect(result[:status].exitstatus).to equal(0)
    expect(Dir.exist?(File.join(SPEC_DIRECTORY, 'fixtures', 'modules', 'ntp'))).to eq(true)
  end
end
