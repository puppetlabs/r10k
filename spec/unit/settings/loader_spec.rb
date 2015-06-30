require 'spec_helper'
require 'r10k/settings/loader'

describe R10K::Settings::Loader do

  context 'populate_loadpath' do
    it 'includes /etc/puppetlabs/r10k/r10k.yaml in the loadpath' do
      expect(subject.loadpath).to include('/etc/puppetlabs/r10k/r10k.yaml')
    end

    it 'includes /etc/r10k.yaml in the loadpath' do
      expect(subject.loadpath).to include('/etc/r10k.yaml')
    end

    it 'does include the current working directory in the loadpath' do
      allow(Dir).to receive(:getwd).and_return '/some/random/path/westvletren'
      expect(subject.loadpath).to include('/some/random/path/westvletren/r10k.yaml')
    end

    it 'does not include /some/random/path/atomium/r10k.yaml in the loadpath' do
      expect(subject.loadpath).not_to include('/some/random/path/atomium/r10k.yaml')
    end

  end

  context 'search' do
    it 'returns the correct default location' do
      allow(File).to receive(:file?).and_return false
      allow(File).to receive(:file?).with('/etc/puppetlabs/r10k/r10k.yaml').and_return true
      allow(File).to receive(:file?).with('/etc/r10k.yaml').and_return true
      expect(subject.search).to eq '/etc/puppetlabs/r10k/r10k.yaml'
    end

    it 'issues a warning if both default locations are present' do
      allow(File).to receive(:file?).and_return false
      allow(File).to receive(:file?).with('/etc/puppetlabs/r10k/r10k.yaml').and_return true
      allow(File).to receive(:file?).with('/etc/r10k.yaml').and_return true

      logger_dbl = double('Logging')
      allow(subject).to receive(:logger).and_return logger_dbl

      expect(logger_dbl).to receive(:warn).with('Both /etc/puppetlabs/r10k/r10k.yaml and /etc/r10k.yaml configuration files exist.')
      expect(logger_dbl).to receive(:warn).with('/etc/puppetlabs/r10k/r10k.yaml will be used.')

      subject.search
    end

    it 'issues a warning if the old location is used' do
      allow(File).to receive(:file?).and_return false
      allow(File).to receive(:file?).with('/etc/puppetlabs/r10k/r10k.yaml').and_return false
      allow(File).to receive(:file?).with('/etc/r10k.yaml').and_return true

      logger_dbl = double('Logging')
      allow(subject).to receive(:logger).and_return logger_dbl

      expect(logger_dbl).to receive(:warn).with("The r10k configuration file at /etc/r10k.yaml is deprecated.")
      expect(logger_dbl).to receive(:warn).with('Please move your r10k configuration to /etc/puppetlabs/r10k/r10k.yaml.')

      subject.search
    end

    describe 'using an override value' do
      it 'uses the override when set and ignores files in the load path' do
        expect(File).to_not receive(:file?)
        expect(subject.search('/some/override/r10k.yaml')).to eq '/some/override/r10k.yaml'
      end

      it 'ignores a nil override value' do
        allow(File).to receive(:file?).and_return false
        allow(File).to receive(:file?).with('/etc/puppetlabs/r10k/r10k.yaml').and_return true
        allow(File).to receive(:file?).with('/etc/r10k.yaml').and_return true
        expect(subject.search(nil)).to eq('/etc/puppetlabs/r10k/r10k.yaml')
      end
    end
  end

  context '#read' do
    it "raises an error if no config file could be found" do
      expect(subject).to receive(:search).and_return nil
      expect {
        subject.read
      }.to raise_error(R10K::Settings::Loader::ConfigError, "No configuration file given, no config file found in current directory, and no global config present")
    end

    it "raises an error if the YAML file load raises an error" do
      expect(subject).to receive(:search).and_return '/some/path/r10k.yaml'
      expect(YAML).to receive(:load_file).and_raise(Errno::ENOENT, "/no/such/file")
      expect {
        subject.read
      }.to raise_error(R10K::Settings::Loader::ConfigError, "Couldn't load config file: No such file or directory - /no/such/file")
    end

    it "recursively replaces string keys with symbol keys in the parsed structure" do
      expect(subject).to receive(:search).and_return '/some/path/r10k.yaml'
      expect(YAML).to receive(:load_file).and_return({
        'cachedir' => '/var/cache/r10k',
        'git' => {
          'provider' => 'rugged',
        }
      })

      expect(subject.read).to eq({
        :cachedir => '/var/cache/r10k',
        :git => {
          :provider => 'rugged',
        }
      })
    end
  end
end
