require 'spec_helper'

require 'r10k/logging'
require 'r10k/action/deploy/deploy_helpers'

describe R10K::Action::Deploy::DeployHelpers do
  subject do
    Object.new.tap do |o|
      o.extend(R10K::Logging)
      o.extend(described_class)
    end
  end

  describe "checking for a config file" do
    it "logs a warning and exits when no config file was set" do
      logger = subject.logger

      expect(logger).to receive(:fatal).with("No configuration file given, no config file found in current directory, and no global config present")

      expect {
        subject.expect_config!
      }.to exit_with(8)
    end
  end

  describe "checking the write lock setting" do
    it "logs a warning and exits when the write lock is set" do
      logger = subject.logger

      expect(logger).to receive(:fatal).with("Making changes to deployed environments has been administratively disabled.")
      expect(logger).to receive(:fatal).with("Reason: r10k is sleepy and wants to take a nap")

      expect {
        subject.check_write_lock!(deploy: {write_lock: "r10k is sleepy and wants to take a nap"})
      }.to exit_with(16)
    end
  end
end
