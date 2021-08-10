require 'spec_helper'

require 'r10k/deployment'
require 'r10k/action/deploy/environment'

describe R10K::Action::Deploy::Environment do

  subject { described_class.new({config: "/some/nonexistent/path"}, [], {}) }

  it_behaves_like "a deploy action that can be write locked"
  it_behaves_like "a deploy action that requires a config file"

  describe "initializing" do
    it "can accept a cachedir option" do
      described_class.new({cachedir: "/some/nonexistent/cachedir"}, [], {})
    end

    it "can accept a puppetfile option" do
      described_class.new({puppetfile: true}, [], {})
    end

    it "can accept a modules option" do
      described_class.new({modules: true}, [], {})
    end

    it "can accept a default_branch_override option" do
      described_class.new({:'default-branch-override' => 'default_branch_override_name'}, [], {})
    end

    it "can accept a no-force option" do
      described_class.new({:'no-force' => true}, [], {})
    end

    it 'can accept a generate-types option' do
      described_class.new({ 'generate-types': true }, [], {})
    end

    it 'can accept a puppet-path option' do
      described_class.new({ 'puppet-path': '/nonexistent' }, [], {})
    end

    it 'can accept a private-key option' do
      described_class.new({ 'private-key': '/nonexistent' }, [], {})
    end

    it 'can accept a token option' do
      described_class.new({ 'oauth-token': '/nonexistent' }, [], {})
    end

    it 'can accept an app id option' do
      described_class.new({ 'github-app-id': '/nonexistent' }, [], {})
    end

    it 'can accept a ttl option' do
      described_class.new({ 'github-app-ttl': '/nonexistent' }, [], {})
    end

    it 'can accept a ssl private key option' do
      described_class.new({ 'github-app-key': '/nonexistent' }, [], {})
    end

    it 'can accept a exclude-spec option' do
      described_class.new({ :'exclude-spec' => true }, [], {})
    end

    it 'can accept an assume-unchanged option' do
      described_class.new({ :'assume-unchanged' => true }, [], {})
    end

    describe "initializing errors" do
      let (:settings) { { deploy: { purge_levels: [:environment],
                                    purge_whitelist: ['coolfile', 'coolfile2'],
                                    purge_allowlist: ['anothercoolfile']}}}

      subject { described_class.new({config: "/some/nonexistent/path"}, [], settings)}
      it 'errors out when both purge_whitelist and purge_allowlist are set' do
        expect{subject}.to raise_error(R10K::Error, /Values found for both purge_whitelist and purge_allowlist./)
    end
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

    describe "with puppetfile or modules flag" do
      let(:deployment) { R10K::Deployment.new(mock_config) }
      let(:loader) do
        instance_double("R10K::ModuleLoader::Puppetfile",
                        :load => {
                          :modules => ['foo'],
                          :purge_exclusions => [],
                          :managed_directories => [],
                          :desired_contents => []
                        }
                       ).as_null_object
      end

      before do
        expect(R10K::Deployment).to receive(:new).and_return(deployment)
        expect(R10K::ModuleLoader::Puppetfile).to receive(:new).
          and_return(loader).at_least(:once)
      end

      it "syncs the puppetfile content when given the puppetfile flag" do
        expect(loader).to receive(:load).exactly(4).times
        expect(R10K::ContentSynchronizer).to receive(:concurrent_sync).exactly(4).times
        action = described_class.new({config: "/some/nonexistent/path", puppetfile: true}, [], {})
        action.call
      end

      it "syncs the puppetfile when given the modules flag" do
        expect(loader).to receive(:load).exactly(4).times
        expect(R10K::ContentSynchronizer).to receive(:concurrent_sync).exactly(4).times
        action = described_class.new({config: "/some/nonexistent/path", modules: true}, [], {})
        action.call
      end
    end

    describe "with assume-unchanged flag" do
      let(:loader) do
        instance_double("R10K::ModuleLoader::Puppetfile",
                        :load => {
                          :modules => ['foo'],
                          :purge_exclusions => [],
                          :managed_directories => [],
                          :desired_contents => []
                        }
                       ).as_null_object
      end

      before do
        expect(R10K::Deployment).to receive(:new).and_wrap_original do |original, settings|
          original.call(mock_config.merge(settings))
        end
        expect(R10K::ModuleLoader::Puppetfile).to receive(:new).
          and_return(loader).at_least(:once)
      end

      it "assume unchanged flag causes the module definitons to be preloaded by the loader" do
        expect(loader).to receive(:load_metadata).exactly(4).times
        action = described_class.new({:config => "/some/nonexistent/path",
                                      :modules => true,
                                      :'assume-unchanged' => true},
                                      [],
                                      {})
        action.call
      end
    end


    describe "with an environment that doesn't exist" do
      let(:deployment) do
        R10K::Deployment.new(mock_config)
      end

      before do
        expect(R10K::Deployment).to receive(:new).and_return(deployment)
      end

      subject { described_class.new({config: "/some/nonexistent/path"}, %w[not_an_environment], {}) }

      it "logs that the environments can't be deployed and returns false" do
        expect(subject.logger).to receive(:error).with("Environment(s) 'not_an_environment' cannot be found in any source and will not be deployed.")
        logger = subject.logger
        expect(subject.call).to eq false
      end
    end

    describe "with no-force" do
      subject { described_class.new({ config: "/some/nonexistent/path", modules: true, :'no-force' => true}, %w[first], {}) }

      it "tries to preserve local modifications" do
        expect(subject.settings[:overrides][:modules][:force]).to equal(false)
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

    describe "Purging white/allowlist" do

      let(:settings) { { pool_size: 4, deploy: { purge_levels: [:environment], purge_allowlist: ['coolfile', 'coolfile2'] } } }
      let(:overrides) { { environments: {}, modules: { pool_size: 4 }, purging: { purge_levels: [:environment], purge_allowlist: ['coolfile', 'coolfile2'] } } }
      let(:deployment) do
        R10K::Deployment.new(mock_config.merge({overrides: overrides}))
      end
      before do
        expect(R10K::Deployment).to receive(:new).and_return(deployment)
        allow_any_instance_of(R10K::Environment::Base).to receive(:purge!)
      end

      subject { described_class.new({ config: "/some/nonexistent/path", modules: true }, %w[PREFIX_first], settings) }

      it "reads in the purge_allowlist setting and purges accordingly" do
        expect(subject.logger).to receive(:debug).with(/Purging unmanaged content for environment/)
        expect(subject.settings[:overrides][:purging][:purge_allowlist]).to eq(['coolfile', 'coolfile2'])
        subject.call
      end

      describe "purge_whitelist" do
        let (:settings) { { deploy: { purge_levels: [:environment], purge_whitelist: ['coolfile', 'coolfile2'] } } }

        it "reads in the purge_whitelist setting and still sets it to purge_allowlist and purges accordingly" do
          expect(subject.logger).to receive(:debug).with(/Purging unmanaged content for environment/)
          expect(subject.settings[:overrides][:purging][:purge_allowlist]).to eq(['coolfile', 'coolfile2'])
          subject.call
        end
      end
    end

    describe "purge_levels" do
      let(:settings) { { deploy: { purge_levels: purge_levels } } }
      let(:overrides) do
        {
          environments: {
            requested_environments: ['PREFIX_first']
          },
          modules: {
            deploy_modules: true,
            pool_size: 4
          },
          purging: {
            purge_levels: purge_levels
          }
        }
      end

      let(:deployment) do
        R10K::Deployment.new(mock_config.merge({ overrides: overrides }))
      end

      before do
        expect(R10K::Deployment).to receive(:new).and_return(deployment)
        allow_any_instance_of(R10K::Environment::Base).to receive(:purge!)
      end

      subject { described_class.new({ config: "/some/nonexistent/path", modules: true }, %w[PREFIX_first], settings) }

      describe "deployment purge level" do
        let(:purge_levels) { [:deployment] }


        it "updates the source's cache before it purges environments" do
          deployment.sources.each do |source|
            expect(source).to receive(:reload!).ordered
          end
          expect(deployment).to receive(:purge!).ordered
          subject.call
        end

        it "only logs about purging deployment" do
          expect(subject).to receive(:visit_environment).and_wrap_original do |original, env, &block|
            expect(env.logger).to_not receive(:debug).with(/Purging unmanaged puppetfile content/)
            original.call(env)
          end.at_least(:once)

          expect(subject.logger).to receive(:debug).with(/Purging unmanaged environments for deployment/)
          expect(subject.logger).to_not receive(:debug).with(/Purging unmanaged content for environment/)

          subject.call
        end
      end

      describe "environment purge level" do
        let(:purge_levels) { [:environment] }

        it "only logs about purging environment" do
          expect(subject).to receive(:visit_environment).and_wrap_original do |original, env, &block|
            expect(env.logger).to_not receive(:debug).with(/Purging unmanaged puppetfile content/)
            original.call(env)
          end.at_least(:once)
          expect(subject.logger).to receive(:debug).with(/Purging unmanaged content for environment/)
          expect(subject.logger).to_not receive(:debug).with(/Purging unmanaged environments for deployment/)

          subject.call
        end

        it "logs that environment was not purged if deploy failed" do
          expect(subject).to receive(:visit_environment).and_wrap_original do |original, env, &block|
            if env.name =~ /first/
              expect(env).to receive(:deploy) { subject.instance_variable_set(:@visit_ok, false) }
            end
            original.call(env)
          end.at_least(:once)

          expect(subject.logger).to receive(:debug).with(/Not purging unmanaged content for environment/)

          subject.call
        end
      end

      describe "puppetfile purge level" do
        let(:purge_levels) { [:puppetfile] }

        it "only logs about purging puppetfile" do
          allow(R10K::ContentSynchronizer).to receive(:concurrent_sync)
          expect(subject).to receive(:visit_environment).and_wrap_original do |original, env, &block|
            if env.name =~ /first/
              expect(env.logger).to receive(:debug).with(/Purging unmanaged Puppetfile content/)
            end
            original.call(env)
          end.at_least(:once)

          expect(subject.logger).to_not receive(:debug).with(/Purging unmanaged environments for deployment/)
          expect(subject.logger).to_not receive(:debug).with(/Purging unmanaged content for environment/)

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
            },
            overrides: {
              modules: {
                pool_size: 4
              }
            }
          )
        )
      end

      before do
        allow(R10K::Deployment).to receive(:new).and_return(deployment)
        allow_any_instance_of(R10K::Environment::Base).to receive(:purge!)

        allow(subject).to receive(:write_environment_info!)
        expect(subject.logger).not_to receive(:error)
      end

      context 'with generate-types enabled' do
        subject do
          described_class.new(
            {
              config: '/some/nonexistent/path',
              modules: true,
              'generate-types': true
            },
            %w[first second],
            {}
          )
        end

        it 'generate_types is true' do
          expect(subject.settings[:overrides][:environments][:generate_types]).to eq(true)
        end

        it 'only calls puppet generate types on specified environment' do
          settings = subject.instance_variable_get(:@settings)
          settings[:overrides][:environments][:requested_environments] = %w{first}
          subject.instance_variable_set(:@settings, settings)
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
          expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
            allow(environment).to receive(:deploy) { subject.instance_variable_set(:@visit_ok, false) }
            expect(environment).not_to receive(:generate_types!)
            original.call(environment, &block)
          end.twice
          subject.call
        end

        it 'calls puppet generate types on previous puppetfile failure' do
          expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
            allow(environment).to receive(:deploy) do
              subject.instance_variable_set(:@visit_ok, false) if environment.dirname == 'first'
            end

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
              modules: true,
              'generate-types': false
            },
            %w[first],
            {}
          )
        end

        it 'generate_types is false' do
          expect(subject.settings[:overrides][:environments][:generate_types]).to eq(false)
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

      subject { described_class.new({ config: '/some/nonexistent/path', 'puppet-path': '/nonexistent' }, [], {}) }

      it 'sets puppet_path' do
        expect(subject.instance_variable_get(:@puppet_path)).to eq('/nonexistent')
      end
    end

    describe 'with puppet-conf' do

      subject { described_class.new({ config: '/some/nonexistent/path', 'puppet-conf': '/nonexistent' }, [], {}) }

      it 'sets puppet_conf' do
        expect(subject.instance_variable_get(:@puppet_conf)).to eq('/nonexistent')
      end
    end

    describe 'with private-key' do

      subject { described_class.new({ config: '/some/nonexistent/path', 'private-key': '/nonexistent' }, [], {}) }

      it 'sets private_key' do
        expect(subject.instance_variable_get(:@private_key)).to eq('/nonexistent')
      end
    end

    describe 'with oauth-token' do

      subject { described_class.new({ config: '/some/nonexistent/path', 'oauth-token': '/nonexistent' }, [], {}) }

      it 'sets oauth_token' do
        expect(subject.instance_variable_get(:@oauth_token)).to eq('/nonexistent')
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
        @puppetfile = R10K::Puppetfile.new("", {})
      end
    end

    let(:mock_stateful_repo_1) { instance_double("R10K::Git::StatefulRepository", :head => "123456") }
    let(:mock_stateful_repo_2) { instance_double("R10K::Git::StatefulRepository", :head => "654321") }
    let(:mock_git_module_1) do
      instance_double("R10K::Module::Git",
                      :name       => "my_cool_module",
                      :properties => {
                        :type     => :git,
                        :expected => "1.0",
                        :actual   => mock_stateful_repo_1.head
                      })
    end
    let(:mock_git_module_2) do
      instance_double("R10K::Module::Git",
                      :name       => "my_uncool_module",
                      :properties => {
                        :type     => :git,
                        :expected => "0.0.1",
                        :actual   => mock_stateful_repo_2.head
                      })
    end
    let(:mock_forge_module_1) { double(:name => "their_shiny_module", :properties => { :expected => "2.0.0" }) }

    before(:all) do
      @tmp_path = "./tmp-r10k-test-dir/"
      Dir.mkdir(@tmp_path) unless File.exists?(@tmp_path)
    end

    after(:all) do
      File.delete("#{@tmp_path}/.r10k-deploy.json")
      Dir.delete(@tmp_path)
    end

    it "writes the .r10k-deploy file correctly if all goes well" do
      fake_env = Fake_Environment.new(@tmp_path, {:name => "my_cool_environment", :signature => "pablo picasso"})
      allow(fake_env).to receive(:modules).and_return([mock_git_module_1, mock_git_module_2, mock_forge_module_1])
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
      expect(r10k_deploy['module_deploys'][1]['name']).to eq("my_uncool_module")
      expect(r10k_deploy['module_deploys'][1]['version']).to eq("0.0.1")
      expect(r10k_deploy['module_deploys'][1]['sha']).to eq("654321")
      expect(r10k_deploy['module_deploys'][2]['name']).to eq("their_shiny_module")
      expect(r10k_deploy['module_deploys'][2]['version']).to eq("2.0.0")
      expect(r10k_deploy['module_deploys'][2]['sha']).to eq(nil)
    end

    it "writes the .r10k-deploy file correctly if there's a failure" do
      fake_env = Fake_Environment.new(@tmp_path, {:name => "my_cool_environment", :signature => "pablo picasso"})
      allow(fake_env).to receive(:modules).and_return([mock_git_module_1, mock_git_module_2, mock_forge_module_1])
      allow(mock_forge_module_1).to receive(:properties).and_raise(StandardError)
      subject.send(:write_environment_info!, fake_env, "2019-01-01 23:23:22 +0000", true)

      file_contents = File.read("#{@tmp_path}/.r10k-deploy.json")
      r10k_deploy = JSON.parse(file_contents)

      expect(r10k_deploy['name']).to eq("my_cool_environment")
      expect(r10k_deploy['signature']).to eq("pablo picasso")
      expect(r10k_deploy['started_at']).to eq("2019-01-01 23:23:22 +0000")
      expect(r10k_deploy['deploy_success']).to eq(true)
      expect(r10k_deploy['module_deploys'].length).to eq(0)
    end
  end
end
