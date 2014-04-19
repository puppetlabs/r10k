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

    it 'uses the ref and a provided source name in the default dirname' do
      subject = described_class.new(ref, remote, '/tmp', nil, "the")
      subject.dirname.should == 'the_master'
    end

    it 'allows a specific dirname to be set' do
      subject = described_class.new(ref, remote, '/tmp', 'sourcename_master')
      subject.dirname.should == 'sourcename_master'
    end
  end

  describe '#sync' do

    let(:working_dir) { double("working_dir") }
    let(:puppetfile_provider) { double("puppetfile_provider") }
    let(:environment) { described_class.new(ref, remote, '/tmp') }

    before :each do
      allow(R10K::Git::WorkingDir).to receive(:new).and_return working_dir
      allow(R10K::PuppetfileProvider::Factory).to receive(:driver).and_return puppetfile_provider
      allow(working_dir).to receive(:sync)
    end

    describe 'working dir is not cloned' do
      it 'should sync puppetfile modules' do
        expect(working_dir).to receive(:cloned?).and_return false
        expect(puppetfile_provider).to receive(:sync_modules)
        environment.sync
      end
    end
    describe 'working dir is cloned' do
      it 'should not sync puppetfile modules' do
        expect(working_dir).to receive(:cloned?).and_return true
        environment.sync
      end
    end
  end
end
