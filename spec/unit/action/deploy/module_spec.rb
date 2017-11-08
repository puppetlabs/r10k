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

    it "can accept a no_force option" do
      described_class.new({no_force: true}, [])
    end
  end

  describe "with no_force" do

    subject { described_class.new({ config: "/some/nonexistent/path", no_force: true}, [] )}

    it "tries to preserve local modifications" do
      expect(subject.no_force).to equal(true)
    end
  end
end
