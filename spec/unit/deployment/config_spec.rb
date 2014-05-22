require 'spec_helper'
require 'r10k/deployment/config'

describe R10K::Deployment::Config do

  let(:settings) { { :cachedir => '/does/not/exist', :some_setting => "some value" } }
  let(:config_loader) { double("config_loader", :search => yaml_config_file) }
  let(:yaml_config_file) { 'some_r10k_config.yaml' }

  describe '#load_config' do
    it 'loads the configuration passed in as an argument' do
      expect(YAML).to receive(:load_file).with(yaml_config_file).and_return settings
      described_class.new.load_config(yaml_config_file)
    end
    it 'searches for the config file when not given a config file' do
      expect(R10K::Deployment::Config::Loader).to receive(:new).and_return config_loader
      expect(YAML).to receive(:load_file).with(yaml_config_file).and_return settings
      described_class.new.load_config(nil)
    end
  end

  describe '#setting' do

    it 'raises an error if accessed before the configuration has been loaded' do
      subject = described_class.new
      expect{subject.setting(:some_setting)}.to raise_error
    end
    it 'returns the value of a setting key' do
      allow(YAML).to receive(:load_file).with(yaml_config_file).and_return settings
      subject = described_class.new
      subject.load_config(yaml_config_file)
      expect(subject.setting(:some_setting)).to eql "some value"
    end
  end

  describe '#self.instance' do
    it 'returns a cached copy of itself when previously called' do
      instance = described_class.instance
      expect(described_class.instance).to eql instance
    end
  end

end