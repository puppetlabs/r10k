require 'puppet_docker_tools/spec_helper'

CURRENT_DIRECTORY = File.dirname(File.dirname(__FILE__))

describe 'Dockerfile' do
  include_context 'with a docker image'
  include_context 'with a docker container' do
    def docker_run_options
      '--entrypoint /bin/bash'
    end
  end

  describe 'uses the correct version of Ubuntu' do
    it_should_behave_like 'a running container', 'cat /etc/lsb-release', nil, 'Ubuntu 16.04'
  end

  describe 'has puppet-agent installed' do
    it_should_behave_like 'a running container', 'dpkg -l puppet-agent', 0
  end

  describe 'has /opt/puppetlabs/puppet/bin/r10k' do
    it_should_behave_like 'a running container', 'stat -L /opt/puppetlabs/puppet/bin/r10k', 0, 'Access: \(0755\/\-rwxr\-xr\-x\)'
  end
end
