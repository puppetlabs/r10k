require 'rspec/core'
require 'fileutils'
require 'open3'

SPEC_DIRECTORY = File.dirname(__FILE__)

describe 'r10k container' do
  include Helpers

  def run_r10k(command)
    run_command("docker run --rm \
                   --volume #{File.join(SPEC_DIRECTORY, 'fixtures')}:/test \
                   #{@image} #{command} \
                   --puppetfile /test/Puppetfile")
  end

  before(:all) do
    @image = ENV['PUPPET_TEST_DOCKER_IMAGE']
    if @image.nil?
      error_message = <<-MSG
* * * * *
  PUPPET_TEST_DOCKER_IMAGE environment variable must be set so we
  know which image to test against!
* * * * *
      MSG
      fail error_message
    end
  end

  after(:all) do
    FileUtils.rm_rf(File.join(SPEC_DIRECTORY, 'fixtures', 'modules'))
  end

  it 'should validate the Puppetfile' do
    result = run_r10k('puppetfile check')
    expect(result[:status].exitstatus).to eq(0)
  end

  it 'should install the Puppetfile' do
    result = run_r10k('puppetfile install')
    expect(result[:status].exitstatus).to eq(0)
    expect(Dir.exist?(File.join(SPEC_DIRECTORY, 'fixtures', 'modules', 'ntp'))).to eq(true)
  end
end
