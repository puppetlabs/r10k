require 'spec_helper'
require 'r10k/module'

describe R10K::Module do
  describe 'delegating to R10K::Module::Git' do
    it "accepts args {:git => 'git url}" do
      obj = R10K::Module.new('foo', '/modulepath', :git => 'git url')
      obj.should be_a_kind_of R10K::Module::Git
    end
  end

  describe 'delegating to R10K::Module::Git' do
    it "accepts name matching 'username/modulename' and no args" do
      obj = R10K::Module.new('bar/quux', '/modulepath', [])
      obj.should be_a_kind_of R10K::Module::Forge
    end

    it "accepts name matching 'username/modulename' and a semver argument" do
      obj = R10K::Module.new('bar/quux', '/modulepath', '10.0.0')
      obj.should be_a_kind_of R10K::Module::Forge
    end
  end

  it "raises an error if delegation fails" do
    expect {
      R10K::Module.new('bar-quux', '/modulepath', ["NOPE NOPE NOPE NOPE!"])
    }.to raise_error RuntimeError, /doesn't have an implementation/
  end
end
