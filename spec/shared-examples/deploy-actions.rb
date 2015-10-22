require 'spec_helper'

require 'r10k/deployment'

shared_examples_for "a deploy action that requires a config file" do
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
    allow(R10K::Deployment).to receive(:new).and_return(deployment)
  end

  it "exits when no config file was provided or found" do
    subject.instance_variable_set(:@config, nil)
    expect {
      subject.call
    }.to exit_with(8)
  end
end

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
    allow(R10K::Deployment).to receive(:new).and_return(deployment)
    subject.settings = {deploy: {write_lock: "Disabled, yo"}}
  end

  it "exits without running when the write lock is set" do
    expect(subject).to_not receive(:visit_deployment)
    expect {
      subject.call
    }.to exit_with(16)
  end
end
