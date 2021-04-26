require 'spec_helper'

require 'r10k/action/deploy/display'

describe R10K::Action::Deploy::Display do
  describe "initializing" do
    it "accepts a puppetfile option" do
      described_class.new({puppetfile: true}, [], {})
    end

    it "accepts a modules option" do
      described_class.new({modules: true}, [], {})
    end

    it "accepts a detail option" do
      described_class.new({detail: true}, [], {})
    end

    it "accepts a format option" do
      described_class.new({format: "json"}, [], {})
    end

    it "accepts a fetch option" do
      described_class.new({fetch: true}, [], {})
    end
  end

  subject { described_class.new({config: "/some/nonexistent/path"}, [], {}) }

  before do
    allow(subject).to receive(:puts)
  end

  it_behaves_like "a deploy action that requires a config file"

  describe "collecting info" do
    subject { described_class.new({config: "/some/nonexistent/path", format: 'json', puppetfile: true, detail: true}, ['first'], {}) }

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

    let(:deployment) { R10K::Deployment.new(mock_config) }

    it "gathers environment info" do
      source_info = subject.send(:source_info, deployment.sources.first, ['first'])
      expect(source_info[:name]).to eq(:control)
      expect(source_info[:environments].length).to eq(1)
      expect(source_info[:environments][0][:name]).to eq('first')
    end
  end
end
