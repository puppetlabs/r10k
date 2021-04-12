require 'rspec/core'
require 'fileutils'
require 'open3'
include Pupperware::SpecHelpers

ENV['SPEC_DIRECTORY'] = File.dirname(__FILE__)
# unifies volume naming
ENV['COMPOSE_PROJECT_NAME'] ||= 'r10k'

RSpec.configure do |c|
  c.before(:suite) do
    ENV['R10K_IMAGE'] = require_test_image
    pull_images(['r10k_check','r10k_install'])
    teardown_cluster()
    # no certs to preload, but if the suite adds puppetserver, be explicit
    docker_compose_up(preload_certs: true)
  end

  c.after(:suite) do
    teardown_cluster()
    FileUtils.rm_rf(File.join(ENV['SPEC_DIRECTORY'], 'fixtures', 'modules'))
  end
end

describe 'r10k container' do
  {
    'r10k_check': 'validate',
    'r10k_install': 'install',
  }.each do |container, op|
    it "should #{op} the Puppetfile" do
      container = get_service_container(container)
      wait_on_container_exit(container)
      expect(get_container_exit_code(container)).to eq(0)
      emit_log(container)
    end
  end
end
