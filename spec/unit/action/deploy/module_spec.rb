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
        allow(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
          expect(environment.puppetfile).to receive(:modules).and_return(
            [R10K::Module::Local.new(environment.name, '/fakedir', {}, environment)]
          ).twice
          original.call(environment, &block)
        end
      end

      it 'generate_types is true' do
        expect(subject.settings[:overrides][:environments][:generate_types]).to eq(true)
      end

      it 'only calls puppet generate types on environments with specified module' do
        expect(subject).to receive(:visit_module).and_wrap_original do |original, mod, &block|
          if mod.name == 'first'
            expect(mod.environment).to receive(:generate_types!)
          else
            expect(mod.environment).not_to receive(:generate_types!)
          end
          original.call(mod, &block)
        end.twice
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

  describe 'with modules' do

    subject { described_class.new({ config: '/some/nonexistent/path' }, ['mod1', 'mod2'], {}) }

    let(:cache) { instance_double("R10K::Git::Cache", 'sanitized_dirname' => 'foo', 'cached?' => true, 'sync' => true) }
    let(:repo) { instance_double("R10K::Git::StatefulRepository", cache: cache, resolve: 'main') }

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

      expect(subject).to receive(:visit_puppetfile).and_wrap_original do |original, puppetfile, &block|
        expect(puppetfile).to receive(:load) do
          puppetfile.add_module('mod1', { git: 'git://remote' })
          puppetfile.add_module('mod2', { git: 'git://remote' })
          puppetfile.add_module('mod3', { git: 'git://remote' })
        end

        original.call(puppetfile, &block)
      end

      expect(subject).to receive(:visit_module).and_wrap_original do |original, mod, &block|
        if ['mod1', 'mod2'].include?(mod.name)
          expect(mod.will_sync?).to be(true)
        else
          expect(mod.will_sync?).to be(false)
        end

        expect(mod).to receive(:sync).and_call_original

        original.call(mod)
      end.exactly(3).times

      expect(repo).to receive(:sync).twice

      subject.call
    end
  end
end

