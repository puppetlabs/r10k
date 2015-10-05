require 'spec_helper'

require 'r10k/deployment'

shared_examples_for "a deploy action that can be write locked" do

  let(:config) do
    R10K::Deployment::MockConfig.new(
      :sources => {
        :control => {
          :type => :mock,
          :basedir => '/some/nonexistent/path/control',
          :environments => %w[first second third],
        },
        :hiera => {
          :type => :mock,
          :basedir => '/some/nonexistent/path/hiera',
          :environments => %w[fourth fifth sixth],
        }
      }
    )
  end

  let(:deployment) { R10K::Deployment.new(config) }

  before do
    allow(R10K::Deployment).to receive(:load_config).and_return(deployment)
  end

  describe "when the write lock is" do

    describe "unset" do
      it "runs normally" do
        expect(subject).to receive(:visit_deployment)
        subject.call
      end
    end

    describe "set" do
      before do
        subject.settings = {deploy: {write_lock: "Disabled, yo"}}
      end

      it "exits without running" do
        expect(subject).to_not receive(:visit_deployment)
        expect {
          subject.call
        }.to exit_with(16)
      end
    end
  end
end
