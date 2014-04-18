require 'spec_helper'
require 'r10k/librarian_environment'

describe R10K::LibrarianEnvironment do

  let(:environment_directory) { '/a/dir/with/a/puppet/file' }
  let(:environment) { double("environment") }

  before :each do
    expect(Librarian::Puppet::Environment).to receive(:new).with(:pwd => environment_directory).and_return environment
  end

  describe "#new" do
    it 'should create a librarian-puppet environment' do
      described_class.new(environment_directory)
    end
  end

  describe '#install!' do
    it 'should call Librarian to install the environment' do
      librarian_install = double('librarian_install', :run => true)
      expect(Librarian::Action::Install).to receive(:new).with(environment, {}).and_return librarian_install
      described_class.new(environment_directory).install!
    end
  end

end