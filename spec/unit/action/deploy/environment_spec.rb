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

    it "can accept a no-force option" do
      described_class.new({:'no-force' => true}, [])
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
            :environments => %w[first second third env-that/will-be-corrected],
            :prefix => 'PREFIX'
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

    describe "with no-force" do
      subject { described_class.new({ config: "/some/nonexistent/path", puppetfile: true, :'no-force' => true}, %w[first]) }

      it "tries to preserve local modifications" do
        expect(subject.force).to equal(false)
      end
    end

    describe "postrun" do
      context "basic postrun hook" do
        let(:settings) { { postrun: ["/path/to/executable", "arg1", "arg2"] } }
        let(:deployment) { R10K::Deployment.new(mock_config.merge(settings)) }

        before do
          expect(R10K::Deployment).to receive(:new).and_return(deployment)
        end

        subject do
          described_class.new( {config: "/some/nonexistent/path" },
                               %w[PREFIX_first],
                               settings                             )
        end

        it "is passed to Subprocess" do
          mock_subprocess = double
          allow(mock_subprocess).to receive(:logger=)
          expect(mock_subprocess).to receive(:execute)

          expect(R10K::Util::Subprocess).to receive(:new).
            with(["/path/to/executable", "arg1", "arg2"]).
            and_return(mock_subprocess)

          subject.call
        end
      end

      context "supports environments" do
        context "when one environment" do
          let(:settings) { { postrun: ["/generate/types/wrapper", "$modifiedenvs"] } }
          let(:deployment) { R10K::Deployment.new(mock_config.merge(settings)) }

          before do
            expect(R10K::Deployment).to receive(:new).and_return(deployment)
          end

          subject do
            described_class.new( {config: "/some/nonexistent/path" },
                                 %w[PREFIX_first],
                                 settings                             )
          end

          it "properly substitutes the environment" do
            mock_subprocess = double
            allow(mock_subprocess).to receive(:logger=)
            expect(mock_subprocess).to receive(:execute)

            expect(R10K::Util::Subprocess).to receive(:new).
              with(["/generate/types/wrapper", "PREFIX_first"]).
              and_return(mock_subprocess)

            subject.call
          end
        end
        context "when many environments" do
          let(:settings) { { postrun: ["/generate/types/wrapper", "$modifiedenvs"] } }
          let(:deployment) { R10K::Deployment.new(mock_config.merge(settings)) }

          before do
            expect(R10K::Deployment).to receive(:new).and_return(deployment)
          end

          subject do
            described_class.new( {config: "/some/nonexistent/path" },
                                 [],
                                 settings                             )
          end

          it "properly substitutes the environment" do
            mock_subprocess = double
            allow(mock_subprocess).to receive(:logger=)
            expect(mock_subprocess).to receive(:execute)

            expect(R10K::Util::Subprocess).to receive(:new).
              with(["/generate/types/wrapper", "PREFIX_first PREFIX_second PREFIX_third PREFIX_env_that_will_be_corrected"]).
              and_return(mock_subprocess)

            subject.call
          end
        end
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

      subject { described_class.new({ config: "/some/nonexistent/path", puppetfile: true }, %w[PREFIX_first], settings) }

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
