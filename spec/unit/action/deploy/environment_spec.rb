require 'spec_helper'

require 'r10k/deployment'
require 'r10k/action/deploy/environment'

describe R10K::Action::Deploy::Environment do

  subject { described_class.new({}, []) }

  it_behaves_like "a deploy action that can be write locked"

  describe "initializing" do
    it "can accept a cachedir option" do
      described_class.new({cachedir: "/some/nonexistent/cachedir"}, [])
    end

    it "can accept a puppetfile option" do
      described_class.new({puppetfile: true}, [])
    end

    it "normalizes environment names in the arg vector"
  end
end
