require 'spec_helper'
require 'r10k/deployment/environment'

describe R10K::Deployment::Environment do
  let(:remote) { 'git://github.com/adrienthebo/r10k-fixture-repo' }
  let(:ref)    { 'master' }

  describe 'dirname' do
    it 'uses the ref as the default dirname' do
      subject = described_class.new(ref, remote, '/tmp')
      subject.dirname.should == 'master'
    end

    it 'allows a specific dirname to be set' do
      subject = described_class.new(ref, remote, '/tmp', 'sourcename_master')
      subject.dirname.should == 'sourcename_master'
    end
  end
end
