require 'spec_helper'
require 'r10k/puppetfile_provider/factory'

describe R10K::PuppetfileProvider::Factory do

  describe '#driver' do
    it 'creates an Internal provider by default' do
      expect(R10K::PuppetfileProvider::Internal).to receive(:new).with("/my/basedir", nil, nil)
      described_class.driver("/my/basedir")
    end

    it 'creates an Internal provider if passed in the :internal argument' do
      expect(R10K::PuppetfileProvider::Internal).to receive(:new).with("/my/basedir", nil, nil)
      described_class.driver("/my/basedir", nil, nil, :internal)
    end
    it 'creates a LibrarianPuppet provider if passed in the :librarian argument' do
      expect(R10K::PuppetfileProvider::LibrarianPuppet).to receive(:new).with("/my/basedir")
      described_class.driver("/my/basedir", nil, nil, :librarian)
    end
    it 'raises an exception if the provider is invalid' do
      expect{described_class.driver("/my/basedir", nil, nil, :invalid)}.to raise_error
    end
  end

end