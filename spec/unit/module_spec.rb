require 'spec_helper'
require 'r10k/module'

describe R10K::Module do
  describe 'delegating to R10K::Module::Git' do
    it "accepts args {:git => 'git url}" do
      obj = R10K::Module.new('foo', '/modulepath', :git => 'git url')
      expect(obj).to be_a_kind_of(R10K::Module::Git)
    end
  end

  describe 'delegating to R10K::Module::Forge' do
    [
      ['bar/quux', []],
      ['bar-quux', []],
      ['bar/quux', ['8.0.0']],
    ].each do |scenario|
      it "accepts a name matching #{scenario[0]} and args #{scenario[1].inspect}" do
        expect(R10K::Module.new(scenario[0], '/modulepath', scenario[1])).to be_a_kind_of(R10K::Module::Forge)
      end
    end
  end

  it "raises an error if delegation fails" do
    expect {
      R10K::Module.new('bar!quux', '/modulepath', ["NOPE NOPE NOPE NOPE!"])
    }.to raise_error RuntimeError, /doesn't have an implementation/
  end
end
