require 'rspec/core'
require 'fileutils'
require 'open3'

SPEC_DIRECTORY = File.dirname(__FILE__)

describe 'r10k container' do

  def run_command(command)
    stdout_string = ''
    status = nil

    Open3.popen3(command) do |stdin, stdout, stderr, wait_thread|
      Thread.new do
        stdout.each { |l| stdout_string << l; STDOUT.puts l }
      end
      Thread.new do
        stderr.each { |l| STDOUT.puts l }
      end

      stdin.close
      status = wait_thread.value
    end

    { status: status, stdout: stdout_string }
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
    result = run_command("docker run --rm --detach \
               --env PUPPERWARE_DISABLE_ANALYTICS=true \
               --entrypoint /bin/bash \
               --interactive \
               --volume #{File.join(SPEC_DIRECTORY, 'fixtures')}:/test \
               #{@image}")
    @container = result[:stdout].chomp

    run_command("docker exec #{@container} cp test/Puppetfile /")
  end

  after(:all) do
    run_command("docker container kill #{@container}")
    FileUtils.rm_rf(File.join(SPEC_DIRECTORY, 'fixtures', 'modules'))
  end

  it 'should validate the Puppetfile' do
    cmd = "docker exec #{@container} r10k puppetfile check"
    result = run_command(cmd)
    expect(result[:status].exitstatus).to eq(0)
  end

  it 'should install the Puppetfile' do
    cmd = "docker exec #{@container} r10k puppetfile install"
    result = run_command(cmd)
    expect(result[:status].exitstatus).to eq(0)
    expect(Dir.exist?(File.join(SPEC_DIRECTORY, 'fixtures', 'modules', 'ntp'))).to eq(true)
  end
end
