require 'rspec/core'
require 'fileutils'

SPEC_DIRECTORY = File.dirname(__FILE__)

describe 'r10k container' do
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
    @container = %x(docker run --rm --detach --entrypoint /bin/bash --interactive --volume #{File.join(SPEC_DIRECTORY, 'fixtures')}:/test #{@image}).chomp
    %x(docker exec #{@container} cp test/Puppetfile /)
  end

  after(:all) do
    %x(docker container kill #{@container})
    FileUtils.rm_rf(File.join(SPEC_DIRECTORY, 'fixtures', 'modules'))
  end

  it 'should validate the Puppetfile' do
    %x(docker exec #{@container} r10k puppetfile check)
    status = $?
    expect(status).to eq(0)
  end

  it 'should install the Puppetfile' do
    %x(docker exec #{@container} r10k puppetfile install)
    status = $?
    expect(status).to eq(0)
    expect(Dir.exist?(File.join(SPEC_DIRECTORY, 'fixtures', 'modules', 'ntp'))).to eq(true)
  end
end
