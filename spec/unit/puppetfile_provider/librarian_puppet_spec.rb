require 'spec_helper'
require 'r10k/puppetfile_provider/librarian_puppet'

describe R10K::PuppetfileProvider::LibrarianPuppet do

  let(:environment_directory) { '/a/dir/with/a/puppet/file' }
  let(:environment) { double("environment", :config_db => config_db) }
  let(:config_db) { double("config_db", :local => {}) }
  let(:librarian) { described_class.new(environment_directory) }

  before :each do
    allow(Librarian::Puppet::Environment).to receive(:new).with(:pwd => environment_directory).and_return environment
  end

  describe '#sync_modules' do
    it 'should delegate to #sync' do
      expect(librarian).to receive(:sync)
      librarian.sync_modules
    end
  end

  describe '#sync' do
    describe 'with an environment having a Puppetfile' do
      it 'should call Librarian to install the environment' do
        allow(File).to receive(:exists?).with("#{environment_directory}/Puppetfile").and_return true
        librarian_install = double('librarian_install', :run => true)
        expect(Librarian::Action::Install).to receive(:new).with(environment, {}).and_return librarian_install
        librarian.sync
      end
    end

    describe 'with an environment with a Puppetfile' do
      it 'should not call Librarian to install the environment' do
        allow(File).to receive(:exists?).with("#{environment_directory}/Puppetfile").and_return false
        librarian.sync
      end
    end


  end

  describe '#purge' do
    describe 'when Librarian is destructive' do
      it 'should delegate to #sync' do
        environment.config_db.local['destructive'] = 'true'
        expect(librarian).to receive(:sync)
        librarian.purge
        expect(environment.config_db.local['destructive']).to eql 'true'
      end
    end
    describe 'when Librarian is not destructive' do

      before :each do
        environment.config_db.local['destructive'] = 'false'
        expect(librarian).to receive(:while_destructive).and_call_original
        expect(environment.config_db.local['destructive']).to eql 'false'
      end

      it 'temporarily enables destruction when #sync is called' do
        expect(librarian).to receive(:sync)
        librarian.purge
      end
      it 'stays non-destructive when there is a problem calling #sync' do
        expect(librarian).to receive(:sync).and_raise Exception
        expect{librarian.purge}.to raise_error
      end
    end

  end

end