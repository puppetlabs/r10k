require 'spec_helper'
require 'r10k/puppetfile_provider/librarian_puppet'

describe R10K::PuppetfileProvider::LibrarianPuppet do

  let(:environment_directory) { '/a/dir/with/a/puppet/file' }
  let(:environment) { double("environment", :config_db => config_db) }
  let(:config_db) { double("config_db", :local => {}) }
  let(:librarian) { described_class.new(environment_directory) }
  let(:module1) { double('module1', :name => 'mod1', :defined_version => '1') }
  let(:module2) { double('module2', :name => 'mod2', :defined_version => '1.3') }

  before :each do
    allow(Librarian::Puppet::Environment).to receive(:new).with(:pwd => environment_directory).and_return environment
    allow(environment).to receive(:lock).and_return double('lock', :manifests => [module1, module2])
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
      end

      it 'temporarily enables destruction when #sync is called' do
        expect(librarian).to receive(:sync)
        librarian.purge
        expect(environment.config_db.local['destructive']).to eql 'false'
      end
      it 'stays non-destructive when there is a problem calling #sync' do
        expect(librarian).to receive(:sync).and_raise Exception
        expect{librarian.purge}.to raise_error
        expect(environment.config_db.local['destructive']).to eql 'false'
      end
    end

  end

  describe '#modules' do
    describe 'when a Puppetfile exists' do

      before :each do
        allow(File).to receive(:exists?).with("#{environment_directory}/Puppetfile").and_return true
      end

      it 'returns a list of modules' do
        expect(librarian.modules).to match_array [module1, module2]
      end
      it 'has modules that have a version' do
        expect(librarian.modules.first.version).to eql '1'
      end

    end
    describe 'when a Puppetfile does not exist' do
      it 'returns an empty list' do
        allow(File).to receive(:exists?).with("#{environment_directory}/Puppetfile").and_return false
        expect(librarian.modules).to match_array []
      end
    end
  end

  describe '#sync_module' do
    it 'should raise an error when called' do
      expect{librarian.sync_module(module1)}.to raise_error
    end
  end

end