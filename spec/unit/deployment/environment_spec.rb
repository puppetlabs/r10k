require 'spec_helper'
require 'r10k/deployment/environment'

describe R10K::Deployment::Environment do
  let(:remote) { 'git://github.com/adrienthebo/r10k-fixture-repo' }
  let(:ref)    { 'master' }

  it 'should use the ref as the default dirname' do
    subject = described_class.new(ref, remote, '/tmp')
    subject.dirname.should == 'master'
  end
end
