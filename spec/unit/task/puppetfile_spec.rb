require 'spec_helper'
require 'r10k/task/puppetfile'

describe R10K::Task::Puppetfile::Sync do

  let(:puppetfile_provider) { double('puppetfile_provider') }

  describe '#call' do
    it 'syncs the modules from the Puppetfile provider' do
      expect(puppetfile_provider).to receive(:sync)
      described_class.new(puppetfile_provider).call
    end
  end

end

describe R10K::Task::Puppetfile::Purge do

  let(:puppetfile_provider) { double('puppetfile_provider') }

  describe '#call' do
    it 'syncs the modules from the Puppetfile provider' do
      expect(puppetfile_provider).to receive(:purge)
      described_class.new(puppetfile_provider).call
    end
  end

end
