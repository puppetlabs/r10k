require 'spec_helper'

require 'r10k/action/deploy/module'

describe R10K::Action::Deploy::Module do

  subject { described_class.new({config: "/some/nonexistent/path"}, [], {}) }

  it_behaves_like "a deploy action that requires a config file"
  it_behaves_like "a deploy action that can be write locked"

  describe "initializing" do
    it "accepts an environment option" do
      described_class.new({environment: "production"}, [], {})
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

    it 'can accept a puppet-conf option' do
      described_class.new({ 'puppet-conf': '/nonexistent' }, [], {})
    end

    it 'can accept a cachedir option' do
      described_class.new({ cachedir: '/nonexistent' }, [], {})
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
  end

  describe "with no-force" do

    subject { described_class.new({ config: "/some/nonexistent/path", :'no-force' => true}, [], {}) }

    it "tries to preserve local modifications" do
      expect(subject.settings[:overrides][:modules][:force]).to equal(false)
    end
  end

  describe 'generate-types' do
    let(:deployment) do
      R10K::Deployment.new(
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
    end

    before do
      allow(R10K::Deployment).to receive(:new).and_return(deployment)
    end

    context 'with generate-types enabled' do
      subject do
        described_class.new(
          {
            config: '/some/nonexistent/path',
            'generate-types': true
          },
          %w[first],
          {}
        )
      end

      it 'generate_types is true' do
        expect(subject.settings[:overrides][:environments][:generate_types]).to eq(true)
      end

      it 'only calls puppet generate types on environments where the specified module was updated' do
        allow(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
          if environment.name == 'first'
            expect(environment).to receive(:deploy).and_return(['first'])
            expect(environment).to receive(:generate_types!)
          else
            expect(environment).to receive(:deploy).and_return([])
            expect(environment).not_to receive(:generate_types!)
          end
          original.call(environment, &block)
        end
        subject.call
      end
    end

    context 'with generate-types disabled' do
      subject do
        described_class.new(
          {
            config: '/some/nonexistent/path',
            'generate-types': false
          },
          %w[first],
          {}
        )
      end

      it 'generate_types is false' do
        expect(subject.settings[:overrides][:environments][:generate_types]).to eq(false)
      end

      it 'does not call puppet generate types' do |it|
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

  describe 'with cachedir' do

    subject { described_class.new({ config: '/some/nonexistent/path', cachedir: '/nonexistent' }, [], {}) }

    it 'sets cachedir' do
      expect(subject.instance_variable_get(:@cachedir)).to eq('/nonexistent')
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

    it 'sets token_path' do
      expect(subject.instance_variable_get(:@oauth_token)).to eq('/nonexistent')
    end
  end

  describe 'with github-app-id' do

    subject { described_class.new({ config: '/some/nonexistent/path', 'github-app-id': '/nonexistent' }, [], {}) }

    it 'sets github-app-id' do
      expect(subject.instance_variable_get(:@github_app_id)).to eq('/nonexistent')
    end
  end

  describe 'with github-app-key' do

    subject { described_class.new({ config: '/some/nonexistent/path', 'github-app-key': '/nonexistent' }, [], {}) }

    it 'sets github-app-key' do
      expect(subject.instance_variable_get(:@github_app_key)).to eq('/nonexistent')
    end
  end

  describe 'with github-app-ttl' do

    subject { described_class.new({ config: '/some/nonexistent/path', 'github-app-ttl': '/nonexistent' }, [], {}) }

    it 'sets github-app-ttl' do
      expect(subject.instance_variable_get(:@github_app_ttl)).to eq('/nonexistent')
    end
  end

  describe 'with modules' do

    subject { described_class.new({ config: '/some/nonexistent/path' }, ['mod1', 'mod2'], {git: {default_ref: 'main'}}) }

    let(:cache) { instance_double("R10K::Git::Cache", 'sanitized_dirname' => 'foo', 'cached?' => true, 'sync' => true) }
    let(:repo) { instance_double("R10K::Git::StatefulRepository", cache: cache, resolve: 'main', tracked_paths: []) }

    it 'does not sync modules not given' do
      allow(R10K::Deployment).to receive(:new).and_wrap_original do |original, settings, &block|
        original.call(settings.merge({
          sources: {
            main: {
              remote: 'git://not/a/remote',
              basedir: '/not/a/basedir',
              type: 'git'
            }
          }
        }))
      end

      allow(R10K::Git::StatefulRepository).to receive(:new).and_return(repo)
      allow(R10K::Git).to receive_message_chain(:cache, :generate).and_return(cache)
      allow_any_instance_of(R10K::Source::Git).to receive(:environment_names).and_return([R10K::Environment::Name.new('first', {})])

      expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
        # For this test we want to have realistic Modules and access to
        # their internal Repos to validate the sync. Unfortunately, to
        # do so we do some invasive mocking, effectively implementing
        # our own R10K::ModuleLoader::Puppetfile#load. We directly update
        # the Environment's internal ModuleLoader and then call `load` on
        # it so it will create the correct loaded_content.
        loader = environment.loader
        allow(loader).to receive(:puppetfile_content).and_return('')
        expect(loader).to receive(:load) do
          loader.add_module('mod1', { git: 'git://remote' })
          loader.add_module('mod2', { git: 'git://remote' })
          loader.add_module('mod3', { git: 'git://remote' })

          loaded_content = loader.load!
          loaded_content[:modules].each do |mod|
            if ['mod1', 'mod2'].include?(mod.name)
              expect(mod.should_sync?).to be(true)
            else
              expect(mod.should_sync?).to be(false)
            end
            expect(mod).to receive(:sync).and_call_original
          end

          loaded_content
        end

        original.call(environment, &block)
      end

      expect(repo).to receive(:sync).twice

      subject.call
    end
  end

  describe 'with environments' do
    subject { described_class.new({ config: '/some/nonexistent/path', environment: 'first' }, ['mod1'], {git: {default_ref: 'main'}}) }

    let(:cache) { instance_double("R10K::Git::Cache", 'sanitized_dirname' => 'foo', 'cached?' => true, 'sync' => true) }
    let(:repo) { instance_double("R10K::Git::StatefulRepository", cache: cache, resolve: 'main', tracked_paths: []) }

    it 'only syncs to the given environments' do
      allow(R10K::Deployment).to receive(:new).and_wrap_original do |original, settings, &block|
        original.call(settings.merge({
          sources: {
            main: {
              remote: 'git://not/a/remote',
              basedir: '/not/a/basedir',
              type: 'git'
            }
          }
        }))
      end

      allow(R10K::Git::StatefulRepository).to receive(:new).and_return(repo)
      allow(R10K::Git).to receive_message_chain(:cache, :generate).and_return(cache)
      allow_any_instance_of(R10K::Source::Git).to receive(:environment_names).and_return([R10K::Environment::Name.new('first', {}),
                                                                                     R10K::Environment::Name.new('second', {})])

      expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
        loader = environment.loader

        if environment.name == 'first'
          # For this test we want to have realistic Modules and access to
          # their internal Repos to validate the sync. Unfortunately, to
          # do so we do some invasive mocking, effectively implementing
          # our own R10K::ModuleLoader::Puppetfile#load. We directly update
          # the Environment's internal ModuleLoader and then call `load` on
          # it so it will create the correct loaded_content.
          allow(loader).to receive(:puppetfile_content).and_return('')
          expect(loader).to receive(:load) do
            loader.add_module('mod1', { git: 'git://remote' })
            loader.add_module('mod2', { git: 'git://remote' })

            loaded_content = loader.load!
            loaded_content[:modules].each do |mod|
              if mod.name == 'mod1'
                expect(mod.should_sync?).to be(true)
              else
                expect(mod.should_sync?).to be(false)
              end
              expect(mod).to receive(:sync).and_call_original
            end

            loaded_content
          end

        else
          expect(loader).not_to receive(:load)
        end

        original.call(environment, &block)
      end.twice

      expect(repo).to receive(:sync).once
      expect(subject.logger).to receive(:debug1).with(/Updating modules.*in environment.*first/i)
      expect(subject.logger).to receive(:debug1).with(/skipping environment.*second/i)

      subject.call
    end
  end


  describe "postrun" do
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

    context "basic postrun hook" do
      let(:settings) { { postrun: ["/path/to/executable", "arg1", "arg2"] } }
      let(:deployment) { R10K::Deployment.new(mock_config.merge(settings)) }

      before do
        expect(R10K::Deployment).to receive(:new).and_return(deployment)
      end

      subject do
        described_class.new({config: "/some/nonexistent/path" },
                            ['mod1'], settings)
      end

      it "is passed to Subprocess" do
        mock_subprocess = double
        allow(mock_subprocess).to receive(:logger=)
        expect(mock_subprocess).to receive(:execute)

        expect(R10K::Util::Subprocess).to receive(:new).
          with(["/path/to/executable", "arg1", "arg2"]).
          and_return(mock_subprocess)

        expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
          modified = subject.instance_variable_get(:@modified_envs) << environment
          subject.instance_variable_set(:modified_envs, modified)
        end.exactly(3).times

        subject.call
      end
    end

    context "supports environments" do
      context "with one environment" do
        let(:settings) { { postrun: ["/generate/types/wrapper", "$modifiedenvs"] } }
        let(:deployment) { R10K::Deployment.new(mock_config.merge(settings)) }

        before do
          expect(R10K::Deployment).to receive(:new).and_return(deployment)
        end

        subject do
          described_class.new({ config: '/some/nonexistent/path',
                                environment: 'first' },
                               ['mod1'], settings)
        end

        it "properly substitutes the environment" do
          mock_subprocess = double
          allow(mock_subprocess).to receive(:logger=)
          expect(mock_subprocess).to receive(:execute)

          expect(R10K::Util::Subprocess).to receive(:new).
            with(["/generate/types/wrapper", "first"]).
            and_return(mock_subprocess)

          expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
            if environment.name == 'first'
              expect(environment).to receive(:deploy).and_return(['first'])
            end
            original.call(environment, &block)
          end.exactly(3).times

          subject.call
        end
      end

      context "with all environments" do
        let(:settings) { { postrun: ["/generate/types/wrapper", "$modifiedenvs"] } }
        let(:deployment) { R10K::Deployment.new(mock_config.merge(settings)) }

        before do
          expect(R10K::Deployment).to receive(:new).and_return(deployment)
        end

        subject do
          described_class.new({ config: '/some/nonexistent/path' },
                               ['mod1'], settings)
        end

        it "properly substitutes the environment where modules were deployed" do
          mock_subprocess = double
          allow(mock_subprocess).to receive(:logger=)
          expect(mock_subprocess).to receive(:execute)

          expect(R10K::Util::Subprocess).to receive(:new).
            with(["/generate/types/wrapper", "first third"]).
            and_return(mock_subprocess)

          expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
            if ['first', 'third'].include?(environment.name)
              expect(environment).to receive(:deploy).and_return(['mod1'])
            end
            original.call(environment, &block)
          end.exactly(3).times

          subject.call
        end

        it "does not execute the command if no envs had the module" do
          expect(R10K::Util::Subprocess).not_to receive(:new)

          mock_mod2 = double('mock_mod', name: 'mod2')
          expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
            expect(environment).to receive(:deploy).and_return([])
            original.call(environment, &block)
          end.exactly(3).times

          subject.call
        end
      end
    end
  end
end

