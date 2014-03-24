require 'spec_helper'
require 'r10k/deployment/source'

describe R10K::Deployment::Source do
  let(:name) { 'do_not_name_a_branch_this' }
  let(:remote) { 'git://github.com/adrienthebo/r10k-fixture-repo' }
  let(:basedir)    { '/tmp' }

  describe 'environments', :integration => true do
    it 'uses the name as a prefix when told' do
      subject = described_class.new(name, remote, basedir, true)
      subject.fetch_remote()
      subject.environments.length.should  > 0
      subject.environments.first.dirname.should start_with name
    end

    it 'avoids using the name as a prefix when told' do
      subject = described_class.new(name, remote, basedir, false)
      subject.fetch_remote()
      subject.environments.length.should  > 0
      subject.environments.first.dirname.should_not start_with name
    end
  end

  describe 'environments' do

    let(:branch1) { double(:ref => "branch1") }
    let(:environment1) { double(:ref => "environment1") }
    let(:branch2) { double(:ref => "branch2") }
    let(:environment2) { double(:ref => "environment2") }
    let(:cache)   { double(:sync => nil, :cached? => true, :branches =>  [branch1, branch2] ) }

    before :each do
      R10K::Git::Cache.stub(:generate).and_return(cache)
    end

    context 'when prefix is not set' do
      it 'creates an environment for each git branch' do
        R10K::Deployment::Environment.should_receive(:new).with(branch1, remote, basedir).and_return environment1
        R10K::Deployment::Environment.should_receive(:new).with(branch2, remote, basedir).and_return environment2
        subject = described_class.new(name, remote, basedir, false)
        subject.environments.should  match_array [environment1, environment2]
      end
    end

    context 'when prefix is set' do
      it 'creates an environment for each git branch with source name set' do
        R10K::Deployment::Environment.should_receive(:new).with(branch1, remote, basedir, nil, name).and_return environment1
        R10K::Deployment::Environment.should_receive(:new).with(branch2, remote, basedir, nil, name).and_return environment2
        subject = described_class.new(name, remote, basedir, true)
        subject.environments.should  match_array [environment1, environment2]
      end
    end


  end

end
