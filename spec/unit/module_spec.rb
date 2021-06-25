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
      it "accepts a name matching #{scenario} and version nil" do
        obj = R10K::Module.new(scenario, '/modulepath', { version: nil })
        expect(obj).to be_a_kind_of(R10K::Module::Forge)
      end
    end
    [ {version: '8.0.0'},
      {type: 'forge', version: '8.0.0'},
    ].each do |scenario|
      it "accepts a name matching bar-quux and args #{scenario.inspect}" do
        obj = R10K::Module.new('bar-quux', '/modulepath', scenario)
        expect(obj).to be_a_kind_of(R10K::Module::Forge)
        expect(obj.send(:instance_variable_get, :'@expected_version')).to eq('8.0.0')
      end
    end

    describe 'when the module is ostensibly on disk' do
      before do
        owner = 'theowner'
        module_name = 'themodulename'
        @title = "#{owner}-#{module_name}"
        metadata = <<~METADATA
          {
            "name": "#{@title}",
            "version": "1.2.0"
          }
        METADATA
        @dirname = Dir.mktmpdir
        module_path = File.join(@dirname, module_name)
        FileUtils.mkdir(module_path)
        File.open("#{module_path}/metadata.json", 'w') do |file|
           file.write(metadata)
        end
      end

      it 'sets the expected version to what is found in the metadata' do
        obj = R10K::Module.new(@title, @dirname, {version: nil})
        expect(obj.send(:instance_variable_get, :'@expected_version')).to eq('1.2.0')
      end
    end
  end

  it "raises an error if delegation fails" do
    expect {
      R10K::Module.new('bar!quux', '/modulepath', {version: ["NOPE NOPE NOPE NOPE!"]})
    }.to raise_error RuntimeError, /doesn't have an implementation/
  end

  describe 'when a user passes a `default_branch_override`' do
    [ ['name', {git: 'git url'}],
      ['name', {type: 'git', source: 'git url'}],
      ['name', {svn: 'svn url'}],
      ['name', {type: 'svn', source: 'svn url'}],
      ['namespace-name', {version: '8.0.0'}],
      ['namespace-name', {type: 'forge', version: '8.0.0'}]
    ].each do |(name, options)|
      it 'can handle the default_branch_override option' do
        expect {
          obj = R10K::Module.new(name, '/modulepath', options.merge({default_branch_override: 'foo'}))
          expect(obj).to be_a_kind_of(R10K::Module::Base)
        }.not_to raise_error
      end
    end
  end
end
