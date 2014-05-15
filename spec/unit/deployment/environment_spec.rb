require 'spec_helper'
require 'r10k/deployment/environment'

describe R10K::Deployment::Environment do
  let(:remote) { 'git://github.com/adrienthebo/r10k-fixture-repo' }
  let(:name)    { 'master' }
  let(:ref)     { 'v1.0' }

  describe 'dirname' do
    it 'uses the environment name as the default dirname' do
      subject = described_class.new(name, remote, '/tmp')
      subject.dirname.should == 'master'
    end

    it 'uses the environment name and a provided source name in the default dirname' do
      subject = described_class.new(name, remote, '/tmp', "the")
      subject.dirname.should == 'the_master'
    end

    it 'is not affected by the ref passed in when using the default dirname' do
      subject = described_class.new(name, remote, '/tmp', nil, ref)
      subject.dirname.should == 'master'
    end

    it 'is not affected by the ref passed in when using a provided source name' do
      subject = described_class.new(name, remote, '/tmp', "the", ref)
      subject.dirname.should == 'the_master'
    end

  end

  describe 'ref' do
    it 'is the ref passed as a constructor arg' do
      subject = described_class.new(name, remote, '/tmp', nil, ref)
      subject.ref.should == 'v1.0'
    end

    it 'is the name of the environment if no ref constructor arg is given' do
      subject = described_class.new(name, remote, '/tmp')
      subject.ref.should == 'master'
    end
  end

end
