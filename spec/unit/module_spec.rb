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
        obj = R10K::Module.new(scenario, '/modulepath', { type: 'forge', version: nil })
        expect(obj).to be_a_kind_of(R10K::Module::Forge)
      end
    end
    [ {type: 'forge', version: '8.0.0'},
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
        obj = R10K::Module.new(@title, @dirname, {type: 'forge', version: nil})
        expect(obj.send(:instance_variable_get, :'@expected_version')).to eq('1.2.0')
      end
    end
  end

  it "raises an error if delegation fails" do
    expect {
      R10K::Module.new('bar!quux', '/modulepath', {version: ["NOPE NOPE NOPE NOPE!"]})
    }.to raise_error RuntimeError, /doesn't have an implementation/
  end

  describe 'Given a set of initialization parameters for R10K::Module' do
    [ ['name', {git: 'git url'}],
      ['name', {type: 'git', source: 'git url'}],
      ['name', {svn: 'svn url'}],
      ['name', {type: 'svn', source: 'svn url'}],
      ['namespace-name', {type: 'forge', version: '8.0.0'}]
    ].each do |(name, options)|
      it 'can handle the default_branch_override option' do
        expect {
          obj = R10K::Module.new(name, '/modulepath', options.merge({default_branch_override: 'foo'}))
          expect(obj).to be_a_kind_of(R10K::Module::Base)
        }.not_to raise_error
      end
      describe 'the exclude_spec setting' do
        it 'sets the exclude_spec instance variable to false by default' do
          obj = R10K::Module.new(name, '/modulepath', options)
          expect(obj.instance_variable_get("@exclude_spec")).to eq(false)
        end
        it 'sets the exclude_spec instance variable' do
          obj = R10K::Module.new(name, '/modulepath', options.merge({exclude_spec: true}))
          expect(obj.instance_variable_get("@exclude_spec")).to eq(true)
        end
        it 'cannot be overridden by the settings from the cli, r10k.yaml, or settings default' do
          options = options.merge({exclude_spec: true, overrides: {modules: {exclude_spec: false}}})
          obj = R10K::Module.new(name, '/modulepath', options)
          expect(obj.instance_variable_get("@exclude_spec")).to eq(true)
        end
        it 'reads the setting from the cli, r10k.yaml, or settings default when not provided directly' do
          options = options.merge({overrides: {modules: {exclude_spec: true}}})
          obj = R10K::Module.new(name, '/modulepath', options)
          expect(obj.instance_variable_get("@exclude_spec")).to eq(true)
        end
      end
    end
  end
end
