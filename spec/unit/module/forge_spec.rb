require 'r10k/module/forge'
require 'spec_helper'

describe R10K::Module::Forge do
  before :all do
    Object.expects(:systemu).never
  end

  describe "implementing the Puppetfile spec" do
    it "should implement 'branan/eight_hundred', '8.0.0'" do
      described_class.should be_implement('branan/eight_hundred', '8.0.0')
    end

    it "should fail with an invalid full name" do
      described_class.should_not be_implement('branan-eight_hundred', '8.0.0')
    end

    it "should fail with an invalid version" do
      described_class.should_not be_implement('branan-eight_hundred', 'not a semantic version')
    end
  end

  subject { described_class.new('branan/eight_hundred', '/moduledir', '8.0.0') }
  it "should set 'name' to the module name" do
    subject.name.should eq 'eight_hundred'
  end
end
