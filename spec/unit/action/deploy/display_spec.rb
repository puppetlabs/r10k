require 'spec_helper'

require 'r10k/action/deploy/display'

describe R10K::Action::Deploy::Display do
  describe "initializing" do
    it "accepts a puppetfile option" do
      described_class.new({puppetfile: true}, [])
    end

    it "accepts a modules option" do
      described_class.new({modules: true}, [])
    end

    it "accepts a detail option" do
      described_class.new({detail: true}, [])
    end

    it "accepts a format option" do
      described_class.new({format: "json"}, [])
    end

    it "accepts a fetch option" do
      described_class.new({fetch: true}, [])
    end
  end

  subject { described_class.new({config: "/some/nonexistent/path"}, []) }

  before do
    allow(subject).to receive(:puts)
  end

  it_behaves_like "a deploy action that requires a config file"
end
