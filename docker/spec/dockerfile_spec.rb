require 'rspec/core'
require 'fileutils'
require 'open3'

SPEC_DIRECTORY = File.dirname(__FILE__)

describe 'r10k container' do
  include Pupperware::SpecHelpers
  def run_r10k(command)
    run_command("docker run --detach \
                   --volume #{File.join(SPEC_DIRECTORY, 'fixtures')}:/home/puppet/test \
                   #{@image} #{command} \
                   --verbose \
                   --trace \
                   --puppetfile test/Puppetfile")
  end

  before(:all) do
    @image = require_test_image
  end

  after(:all) do
    FileUtils.rm_rf(File.join(SPEC_DIRECTORY, 'fixtures', 'modules'))
  end

  it 'should validate the Puppetfile' do
    result = run_r10k('puppetfile check')
    container = result[:stdout].chomp
    wait_on_container_exit(container)
    expect(get_container_exit_code(container)).to eq(0)
    emit_log(container)
    teardown_container(container)
  end

  it 'should install the Puppetfile' do
    result = run_r10k('puppetfile install')
    container = result[:stdout].chomp
    wait_on_container_exit(container)
    expect(get_container_exit_code(container)).to eq(0)
    emit_log(container)
    teardown_container(container)
  end
end
