require 'spec_helper'

require 'r10k/deployment'
require 'r10k/action/deploy/environment'

describe R10K::Action::Deploy::Environment do

  subject { described_class.new({config: "/some/nonexistent/path"}, []) }

  it_behaves_like "a deploy action that can be write locked"
  it_behaves_like "a deploy action that requires a config file"

  describe "initializing" do
    it "can accept a cachedir option" do
      described_class.new({cachedir: "/some/nonexistent/cachedir"}, [])
    end

    it "can accept a puppetfile option" do
      described_class.new({puppetfile: true}, [])
    end

    it "normalizes environment names in the arg vector"
  end

  describe "when called" do
    let(:mock_config) do
      R10K::Deployment::MockConfig.new(
        :sources => {
          :control => {
            :type => :mock,
            :basedir => '/some/nonexistent/path/control',
            :environments => %w[first second third],
          }
        }
      )
    end

    describe "with an environment that doesn't exist" do
      let(:deployment) do
        R10K::Deployment.new(mock_config)
      end

      before do
        expect(R10K::Deployment).to receive(:new).and_return(deployment)
      end

      subject { described_class.new({config: "/some/nonexistent/path"}, %w[not_an_environment]) }

      it "logs that the environments can't be deployed and returns false" do
        expect(subject.logger).to receive(:error).with("Environment(s) 'not_an_environment' cannot be found in any source and will not be deployed.")
        logger = subject.logger
        expect(subject.call).to eq false
      end
    end

    describe "purge_levels" do
      let(:settings) { { deploy: { purge_levels: purge_levels } } }

      let(:deployment) do
        R10K::Deployment.new(mock_config.merge(settings))
      end

      before do
        expect(R10K::Deployment).to receive(:new).and_return(deployment)
      end

      subject { described_class.new({ config: "/some/nonexistent/path", puppetfile: true }, %w[first], settings) }

      describe "deployment purge level" do
        let(:purge_levels) { [:deployment] }

        it "only logs about purging deployment" do
          expect(subject.logger).to receive(:debug).with(/purging unmanaged environments for deployment/i)
          expect(subject.logger).to_not receive(:debug).with(/purging unmanaged content for environment/i)
          expect(subject.logger).to_not receive(:debug).with(/purging unmanaged puppetfile content/i)

          subject.call
        end
      end

      describe "environment purge level" do
        let(:purge_levels) { [:environment] }

        it "only logs about purging environment" do
          expect(subject.logger).to receive(:debug).with(/purging unmanaged content for environment/i)
          expect(subject.logger).to_not receive(:debug).with(/purging unmanaged environments for deployment/i)
          expect(subject.logger).to_not receive(:debug).with(/purging unmanaged puppetfile content/i)

          subject.call
        end

        it "logs that environment was not purged if deploy failed" do
          expect(subject).to receive(:visit_puppetfile) { subject.instance_variable_set(:@visit_ok, false) }

          expect(subject.logger).to receive(:debug).with(/not purging unmanaged content for environment/i)

          subject.call
        end
      end

      describe "puppetfile purge level" do
        let(:purge_levels) { [:puppetfile] }

        it "only logs about purging puppetfile" do
          expect(subject.logger).to receive(:debug).with(/purging unmanaged puppetfile content/i)
          expect(subject.logger).to_not receive(:debug).with(/purging unmanaged environments for deployment/i)
          expect(subject.logger).to_not receive(:debug).with(/purging unmanaged content for environment/i)

          subject.call
        end
      end
    end
  end
end
