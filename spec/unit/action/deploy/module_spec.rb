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

      before do
        @modules = []
        allow(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
          mod = R10K::Module::Local.new(environment.name, '/fakedir', {}, environment)
          if mod.name == 'first'
            expect(environment).to receive(:generate_types!)
          else
            expect(environment).not_to receive(:generate_types!)
          end
          @modules << mod
          expect(environment.puppetfile).to receive(:modules).and_return([mod]).twice
          original.call(environment, &block)
        end
      end

      it 'generate_types is true' do
        expect(subject.settings[:overrides][:environments][:generate_types]).to eq(true)
      end

      it 'only calls puppet generate types on environments with specified module' do
        subject.call
        expect(@modules.length).to be(2)
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

  describe 'with modules' do

    subject { described_class.new({ config: '/some/nonexistent/path' }, ['mod1', 'mod2'], {}) }

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
      allow_any_instance_of(R10K::Source::Git).to receive(:branch_names).and_return([R10K::Environment::Name.new('first', {})])

      expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
        puppetfile = environment.puppetfile
        loader = puppetfile.loader
        expect(puppetfile).to receive(:load) do
          loader.add_module('mod1', { git: 'git://remote' })
          loader.add_module('mod2', { git: 'git://remote' })
          loader.add_module('mod3', { git: 'git://remote' })

          allow(loader).to receive(:puppetfile_content).and_return('')
          loaded_content = loader.load!
          puppetfile.instance_variable_set(:@loaded_content, loaded_content)
          puppetfile.instance_variable_set(:@loaded, true)
        end

        loader.modules.each do |mod|
          if ['mod1', 'mod2'].include?(mod.name)
            expect(mod.should_sync?).to be(true)
          else
            expect(mod.should_sync?).to be(false)
          end
          expect(mod).to receive(:sync).and_call_original
        end

        original.call(environment, &block)
      end

      expect(repo).to receive(:sync).twice

      subject.call
    end
  end

  describe 'with environments' do
    subject { described_class.new({ config: '/some/nonexistent/path', environment: 'first' }, ['mod1'], {}) }

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
      allow_any_instance_of(R10K::Source::Git).to receive(:branch_names).and_return([R10K::Environment::Name.new('first', {}),
                                                                                     R10K::Environment::Name.new('second', {})])

      expect(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
        puppetfile = environment.puppetfile

        if environment.name == 'first'
          loader = puppetfile.loader
          expect(puppetfile).to receive(:load) do
            loader.add_module('mod1', { git: 'git://remote' })
            loader.add_module('mod2', { git: 'git://remote' })

            allow(loader).to receive(:puppetfile_content).and_return('')
            loaded_content = loader.load!
            puppetfile.instance_variable_set(:@loaded_content, loaded_content)
            puppetfile.instance_variable_set(:@loaded, true)
          end

          loader.modules.each do |mod|
            if mod.name == 'mod1'
              expect(mod.should_sync?).to be(true)
            else
              expect(mod.should_sync?).to be(false)
            end
            expect(mod).to receive(:sync).and_call_original
          end
        else
          expect(puppetfile).not_to receive(:load)
        end

        original.call(environment, &block)
      end.twice

      expect(repo).to receive(:sync).once
      expect(subject.logger).to receive(:debug1).with(/Updating modules.*in environment.*first/i)
      expect(subject.logger).to receive(:debug1).with(/skipping environment.*second/i)

      subject.call
    end
  end
end

