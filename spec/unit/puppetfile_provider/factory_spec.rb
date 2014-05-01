require 'spec_helper'
require 'r10k/puppetfile_provider/factory'

describe R10K::PuppetfileProvider::Factory do

  describe '#driver' do
    it 'creates an Internal PuppetProvider' do
      expect(R10K::PuppetfileProvider::Internal).to receive(:new).with("a", "b", "c")
      described_class.driver("a", "b", "c")
    end
  end

end