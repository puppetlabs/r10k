require 'spec_helper'
require 'r10k/puppetfile_provider/internal'

describe R10K::PuppetfileProvider::Internal do

  let(:environment_directory) { '/a/dir/with/a/puppet/file' }
  let(:puppetfile) { double('puppetfile') }
  let(:module1) { double('module1', :name => 'mod1', :version => '1') }
  let(:module2) { double('module2', :name => 'mod2', :version => '1.3') }
  let(:internal) { described_class.new(environment_directory) }

  before :each do
    allow(R10K::Puppetfile).to receive(:new).and_return puppetfile
    allow(puppetfile).to receive(:load)
    allow(puppetfile).to receive(:modules).and_return [module1, module2]
    allow(puppetfile).to receive(:moduledir).and_return "#{environment_directory}/modules"
  end

  describe '#sync_modules' do
    it 'should sync all modules for a Puppetfile' do
      expect(module1).to receive(:sync)
      expect(module2).to receive(:sync)
      internal.sync_modules
    end
  end

  describe '#sync' do
    it 'should delegate to #sync_modules and then #purge' do
      expect(internal).to receive(:sync_modules)
      expect(internal).to receive(:purge)
      internal.sync
    end
  end

  describe '#purge' do

    describe "when there are stale modules" do
      it 'should call purge on the Puppetfile' do
        expect(puppetfile).to receive(:stale_contents).and_return ["im_stale"]
        expect(puppetfile).to receive(:purge!)
        internal.purge
      end

    end

    describe "when there are no stale modules" do
      it 'does not purge the contents' do
        expect(puppetfile).to receive(:stale_contents).and_return []
        internal.purge
      end

    end

  end

  describe '#modules' do
    describe 'when a Puppetfile exists' do
      it 'returns a list of modules' do
        expect(internal.modules).to match_array [module1, module2]
      end
    end
    describe 'when an environment does not have a Puppetfile' do
      it 'returns an empty list' do
        allow(puppetfile).to receive(:modules).and_return []
        expect(internal.modules).to match_array []
      end

    end


  end

end