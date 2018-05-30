require 'spec_helper'

CURRENT_DIRECTORY = File.dirname(File.dirname(__FILE__))

describe 'Dockerfile' do
  include_context 'with a docker image'

  describe package('puppet-agent') do
    it { is_expected.to be_installed }
  end

  describe file('/opt/puppetlabs/puppet/bin/r10k') do
    it { should exist }
    it { should be_executable }
  end
end
