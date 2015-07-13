require 'spec_helper'

describe R10K::Deployment::Config do
  describe "applying global settings" do
    let(:loader) { instance_double('R10K::Settings::Loader') }
    let(:initializer) { instance_double('R10K::Initializers::GlobalInitializer') }

    before do
      expect(R10K::Settings::Loader).to receive(:new).and_return(loader)
      expect(R10K::Initializers::GlobalInitializer).to receive(:new).and_return(initializer)
    end

    it 'runs application initialization' do
      config = instance_double('Hash')
      allow(loader).to receive(:read).and_return({})
      expect(initializer).to receive(:call)
      described_class.new('some/path')
    end
  end
end
