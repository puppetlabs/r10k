require 'spec_helper'
require 'r10k/environment'

describe R10K::Environment::Base do

  subject(:environment) { described_class.new('envname', '/some/imaginary/path', 'env_name', {}) }

  it "can return the fully qualified path" do
    expect(environment.path).to eq(Pathname.new('/some/imaginary/path/env_name'))
  end

  it "raises an exception when #sync is called" do
    expect { environment.sync }.to raise_error(NotImplementedError)
  end

  describe "accepting a visitor" do
    it "passes itself to the visitor" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit).with(:environment, subject)
      subject.accept(visitor)
    end

    it "passes the visitor to the puppetfile if the visitor yields" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit) do |type, other, &block|
        expect(type).to eq :environment
        expect(other).to eq subject
        block.call
      end

      pf = spy('puppetfile')
      expect(pf).to receive(:accept).with(visitor)

      expect(subject).to receive(:puppetfile).and_return(pf)
      subject.accept(visitor)
    end
  end
end
