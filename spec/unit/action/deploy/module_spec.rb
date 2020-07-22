require 'spec_helper'

require 'r10k/action/deploy/module'

describe R10K::Action::Deploy::Module do

  subject { described_class.new({config: "/some/nonexistent/path"}, []) }

  it_behaves_like "a deploy action that requires a config file"
  it_behaves_like "a deploy action that can be write locked"

  describe "initializing" do
    it "accepts an environment option" do
      described_class.new({environment: "production"}, [])
    end

    it "can accept a no-force option" do
      described_class.new({:'no-force' => true}, [])
    end

    it 'can accept a generate-types option' do
      described_class.new({ 'generate-types': true }, [])
    end

    it 'can accept a puppet-path option' do
      described_class.new({ 'puppet-path': '/nonexistent' }, [])
    end

    it 'can accept a cachedir option' do
      described_class.new({ cachedir: '/nonexistent' }, [])
    end
  end

  describe "with no-force" do

    subject { described_class.new({ config: "/some/nonexistent/path", :'no-force' => true}, [] )}

    it "tries to preserve local modifications" do
      expect(subject.force).to equal(false)
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
          %w[first]
        )
      end

      before do
        allow(subject).to receive(:visit_environment).and_wrap_original do |original, environment, &block|
          expect(environment.puppetfile).to receive(:modules).and_return(
            [R10K::Module::Local.new(environment.name, '/fakedir', [], environment)]
          )
          original.call(environment, &block)
        end
      end

      it 'generate_types is true' do
        expect(subject.instance_variable_get(:@generate_types)).to eq(true)
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
          %w[first]
        )
      end

      it 'generate_types is false' do
        expect(subject.instance_variable_get(:@generate_types)).to eq(false)
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

    subject { described_class.new({ config: '/some/nonexistent/path', 'puppet-path': '/nonexistent' }, []) }

    it 'sets puppet_path' do
      expect(subject.instance_variable_get(:@puppet_path)).to eq('/nonexistent')
    end
  end

  describe 'with cachedir' do

    subject { described_class.new({ config: '/some/nonexistent/path', cachedir: '/nonexistent' }, []) }

    it 'sets puppet_path' do
      expect(subject.instance_variable_get(:@cachedir)).to eq('/nonexistent')
    end
  end
end
