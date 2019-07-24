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

    describe "with no-force" do
      subject { described_class.new({ config: "/some/nonexistent/path", puppetfile: true, :'no-force' => true}, %w[first]) }

      it "tries to preserve local modifications" do
        expect(subject.force).to equal(false)
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
