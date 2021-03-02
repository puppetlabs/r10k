require 'spec_helper'
require 'r10k/module'

describe R10K::Module do
  describe 'delegating to R10K::Module::Git' do
    [ {git: 'git url'},
      {type: 'git', source: 'git url'},
    ].each do |scenario|
      it "accepts a name matching 'test' and args #{scenario.inspect}" do
        obj = R10K::Module.new('test', '/modulepath', scenario)
        expect(obj).to be_a_kind_of(R10K::Module::Git)
        expect(obj.send(:instance_variable_get, :'@remote')).to eq('git url')
      end
    end
  end

  describe 'delegating to R10K::Module::Svn' do
    [ {svn: 'svn url'},
      {type: 'svn', source: 'svn url'},
    ].each do |scenario|
      it "accepts a name matching 'test' and args #{scenario.inspect}" do
        obj = R10K::Module.new('test', '/modulepath', scenario)
        expect(obj).to be_a_kind_of(R10K::Module::SVN)
        expect(obj.send(:instance_variable_get, :'@url')).to eq('svn url')
      end
    end
  end

  describe 'delegating to R10K::Module::Forge' do
    [ 'bar/quux',
      'bar-quux',
    ].each do |scenario|
      it "accepts a name matching #{scenario} and args nil" do
        obj = R10K::Module.new(scenario, '/modulepath', nil)
        expect(obj).to be_a_kind_of(R10K::Module::Forge)
      end
    end
    [ '8.0.0',
      {type: 'forge', version: '8.0.0'},
    ].each do |scenario|
      it "accepts a name matching bar-quux and args #{scenario.inspect}" do
        obj = R10K::Module.new('bar-quux', '/modulepath', scenario)
        expect(obj).to be_a_kind_of(R10K::Module::Forge)
        expect(obj.send(:instance_variable_get, :'@expected_version')).to eq('8.0.0')
      end
    end
  end

  it "raises an error if delegation fails" do
    expect {
      R10K::Module.new('bar!quux', '/modulepath', ["NOPE NOPE NOPE NOPE!"])
    }.to raise_error RuntimeError, /doesn't have an implementation/
  end
end
