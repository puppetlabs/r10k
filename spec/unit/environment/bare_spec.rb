require 'spec_helper'
require 'r10k/environment'

describe R10K::Environment::Bare do
  it "warns on initialization" do
    logger_spy = spy('logger')
    allow_any_instance_of(described_class).to receive(:logger).and_return(logger_spy)

    described_class.new('envname', '/basedir', 'dirname', {})

    expect(logger_spy).to have_received(:warn).with(%r{deprecated.*envname})
  end
end
