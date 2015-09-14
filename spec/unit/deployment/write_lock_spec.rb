require 'spec_helper'

require 'r10k/deployment/write_lock'

describe R10K::Deployment::WriteLock do
  subject { Object.new.extend(described_class) }

  it "logs a warning and exits when the write lock is set" do
    logger = subject.logger

    expect(logger).to receive(:fatal).with("Making changes to deployed environments has been administratively disabled.")
    expect(logger).to receive(:fatal).with("Reason: r10k is sleepy and wants to take a nap")

    expect {
      subject.check_write_lock!(deploy: {write_lock: "r10k is sleepy and wants to take a nap"})
    }.to exit_with(16)
  end
end
