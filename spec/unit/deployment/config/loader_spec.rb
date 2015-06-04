require 'spec_helper'
require 'r10k/deployment/config/loader'

describe R10K::Deployment::Config::Loader do

  context 'populate_loadpath' do
    it 'includes /etc/puppetlabs/r10k/r10k.yaml in the loadpath' do
      expect(subject.loadpath).to include('/etc/puppetlabs/r10k/r10k.yaml')
    end

    it 'does include the current working directory in the loadpath' do
      allow(Dir).to receive(:getwd).and_return '/some/random/path/westvletren'
      expect(subject.loadpath).to include('/some/random/path/westvletren/r10k.yaml')
    end

    # This was the old default location that is no longer supported as of 2.0.0.
    it 'does not include /etc/r10k.yaml in the loadpath' do
      expect(subject.loadpath).not_to include('/etc/r10k.yaml')
    end

    it 'does not include /some/random/path/atomium/r10k.yaml in the loadpath' do
      expect(subject.loadpath).not_to include('/some/random/path/atomium/r10k.yaml')
    end

  end

  context 'search' do
    it 'returns the correct default location' do
      allow(File).to receive(:file?).and_return false
      allow(File).to receive(:file?).with('/etc/puppetlabs/r10k/r10k.yaml').and_return true
      expect(subject.search).to eq '/etc/puppetlabs/r10k/r10k.yaml'
    end
  end
end
