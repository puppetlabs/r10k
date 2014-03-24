require 'spec_helper'
require 'r10k/deployment/environment'

describe R10K::Deployment::Environment do
  let(:remote) { 'git://github.com/adrienthebo/r10k-fixture-repo' }
  let(:name)    { 'master' }

  describe 'dirname' do
    it 'uses the environment name as the default dirname' do
      subject = described_class.new(name, remote, '/tmp')
      subject.dirname.should == 'master'
    end

    it 'uses the environment name and a provided source name in the default dirname' do
      subject = described_class.new(name, remote, '/tmp', "the")
      subject.dirname.should == 'the_master'
    end

  end
end
