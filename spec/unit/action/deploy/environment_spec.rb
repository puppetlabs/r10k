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

    it "can accept a default_branch_override option" do
      described_class.new({:'default-branch-override' => 'default_branch_override_name'}, [])
    end

    it "can accept a no-force option" do
      described_class.new({:'no-force' => true}, [])
    end

    it "normalizes environment names in the arg vector"

    it 'can accept a generate-types option' do
      described_class.new({ 'generate-types': true }, [])
    end

    it 'can accept a puppet-path option' do
      described_class.new({ 'puppet-path': '/nonexistent' }, [])
    end
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
    describe "generate-types" do
      let(:deployment) do
        R10K::Deployment.new(
          R10K::Deployment::MockConfig.new(
            sources: {
              control: {
                type: :mock,
                basedir: '/some/nonexistent/path/control',
                environments: %w[first second]
              }
            }
          )
        )
      end

      before do
        allow(R10K::Deployment).to receive(:new).and_return(deployment)
      end

      before(:each) do
        allow(subject).to receive(:write_environment_info!)
        expect(subject.logger).not_to receive(:error)
      end

      context 'with generate-types enabled' do
        subject do
          described_class.new(
            {
              config: '/some/nonexistent/path',
              puppetfile: true,
              'generate-types': true
            },
            %w[first second]
          )
        end

        it 'generate_types is true' do
          expect(subject.instance_variable_get(:@generate_types)).to eq(true)
        end

        it 'only calls puppet generate types on specified environment' do
          subject.instance_variable_set(:@argv, %w[first])
          expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
            if environment.dirname == 'first'
              expect(environment).to receive(:generate_types!)
            else
              expect(environment).not_to receive(:generate_types!)
            end
            original.call(environment, &block)
          end.twice
          subject.call
        end

        it 'does not call puppet generate types on puppetfile failure' do
          allow(subject).to receive(:visit_puppetfile) { subject.instance_variable_set(:@visit_ok, false) }
          expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
            expect(environment).not_to receive(:generate_types!)
            original.call(environment, &block)
          end.twice
          subject.call
        end

        it 'calls puppet generate types on previous puppetfile failure' do
          allow(subject).to receive(:visit_puppetfile) do |puppetfile|
            subject.instance_variable_set(:@visit_ok, false) if puppetfile.environment.dirname == 'first'
          end
          expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
            if environment.dirname == 'second'
              expect(environment).to receive(:generate_types!)
            else
              expect(environment).not_to receive(:generate_types!)
            end
            original.call(environment, &block)
          end.twice
          subject.call
        end
      end

      context 'with generate-types disabled' do
        subject do
          described_class.new(
            {
              config: '/some/nonexistent/path',
              puppetfile: true,
              'generate-types': false
            },
            %w[first]
          )
        end

        it 'generate_types is false' do
          expect(subject.instance_variable_get(:@generate_types)).to eq(false)
        end

        it 'does not call puppet generate types' do
          expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
            expect(environment).not_to receive(:generate_types!)
            original.call(environment, &block)
          end.twice
          subject.call
        end
      end
    end

    describe 'with puppet-path' do

      subject { described_class.new({ config: '/some/nonexistent/path', 'puppet-path': '/nonexistent' }, []) }

      it 'sets puppet_path' do
        expect(subject.instance_variable_get(:@puppet_path)).to eq('/nonexistent')
      end
    end

    describe 'with puppet-conf' do

      subject { described_class.new({ config: '/some/nonexistent/path', 'puppet-conf': '/nonexistent' }, []) }

      it 'sets puppet_conf' do
        expect(subject.instance_variable_get(:@puppet_conf)).to eq('/nonexistent')
      end
    end
  end

  describe "write_environment_info!" do

    class Fake_Environment
      attr_accessor :path
      attr_accessor :puppetfile
      attr_accessor :info

      def initialize(path, info)
        @path = path
        @info = info
        @puppetfile = R10K::Puppetfile.new
      end
    end

    let(:mock_stateful_repo_1) { instance_double("R10K::Git::StatefulRepository", :head => "123456") }
    let(:mock_stateful_repo_2) { instance_double("R10K::Git::StatefulRepository", :head => "654321") }
    let(:mock_git_module_1) { instance_double("R10K::Module::Git", :name => "my_cool_module", :version => "1.0", :repo => mock_stateful_repo_1) }
    let(:mock_git_module_2) { instance_double("R10K::Module::Git", :name => "my_lame_module", :version => "0.0.1", :repo => mock_stateful_repo_2) }
    let(:mock_forge_module_1) { double(:name => "their_shiny_module", :version => "2.0.0") }
    let(:mock_puppetfile) { instance_double("R10K::Puppetfile", :modules => [mock_git_module_1, mock_git_module_2, mock_forge_module_1]) }

    before(:all) do
      @tmp_path = "./tmp-r10k-test-dir/"
      Dir.mkdir(@tmp_path) unless File.exists?(@tmp_path)
    end

    after(:all) do
      File.delete("#{@tmp_path}/.r10k-deploy.json")
      Dir.delete(@tmp_path)
    end

    it "writes the .r10k-deploy file correctly" do
      allow(R10K::Puppetfile).to receive(:new).and_return(mock_puppetfile)
      allow(mock_forge_module_1).to receive(:repo).and_raise(NoMethodError)

      fake_env = Fake_Environment.new(@tmp_path, {:name => "my_cool_environment", :signature => "pablo picasso"})
      allow(fake_env).to receive(:modules).and_return(mock_puppetfile.modules)
      subject.send(:write_environment_info!, fake_env, "2019-01-01 23:23:22 +0000", true)

      file_contents = File.read("#{@tmp_path}/.r10k-deploy.json")
      r10k_deploy = JSON.parse(file_contents)

      expect(r10k_deploy['name']).to eq("my_cool_environment")
      expect(r10k_deploy['signature']).to eq("pablo picasso")
      expect(r10k_deploy['started_at']).to eq("2019-01-01 23:23:22 +0000")
      expect(r10k_deploy['deploy_success']).to eq(true)
      expect(r10k_deploy['module_deploys'].length).to eq(3)
      expect(r10k_deploy['module_deploys'][0]['name']).to eq("my_cool_module")
      expect(r10k_deploy['module_deploys'][0]['version']).to eq("1.0")
      expect(r10k_deploy['module_deploys'][0]['sha']).to eq("123456")
      expect(r10k_deploy['module_deploys'][1]['name']).to eq("my_lame_module")
      expect(r10k_deploy['module_deploys'][1]['version']).to eq("0.0.1")
      expect(r10k_deploy['module_deploys'][1]['sha']).to eq("654321")
      expect(r10k_deploy['module_deploys'][2]['name']).to eq("their_shiny_module")
      expect(r10k_deploy['module_deploys'][2]['version']).to eq("2.0.0")
      expect(r10k_deploy['module_deploys'][2]['sha']).to eq(nil)

    end
  end
end
