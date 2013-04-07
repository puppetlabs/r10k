require 'spec_helper'
require 'r10k/module'

describe R10K::Module do

  it "should be able to delegate to R10K::Module::Git" do
    obj = R10K::Module.new('foo', '/modulepath', :git => "git url")
    obj.should be_a_kind_of R10K::Module::Git
  end

  it "should be able to delegate to R10K::Module::Forge" do
    obj = R10K::Module.new('bar/quux', '/modulepath', '10.10.10')
    obj.should be_a_kind_of R10K::Module::Forge
  end

  it "should raise an exception if delegation fails" do
    expect {
      R10K::Module.new('bar/quux', '/modulepath', ["NOPE NOPE NOPE NOPE!"])
    }.to raise_error RuntimeError, /doesn't have an implementation/
  end
end
