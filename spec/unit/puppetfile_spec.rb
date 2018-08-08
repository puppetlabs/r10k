require 'spec_helper'
require 'r10k/puppetfile'

describe R10K::Puppetfile do

  subject do
    described_class.new(
      '/some/nonexistent/basedir'
    )
  end

  describe "the default moduledir" do
    it "is the basedir joined with '/modules' path" do
      expect(subject.moduledir).to eq '/some/nonexistent/basedir/modules'
    end
  end

  describe "setting moduledir" do
    it "changes to given moduledir if it is an absolute path" do
      subject.set_moduledir('/absolute/path/moduledir')
      expect(subject.moduledir).to eq '/absolute/path/moduledir'
    end

    it "joins the basedir with the given moduledir if it is a relative path" do
      subject.set_moduledir('relative/moduledir')
      expect(subject.moduledir).to eq '/some/nonexistent/basedir/relative/moduledir'
    end
  end

  describe "adding modules" do
    it "should accept Forge modules with a string arg" do
      allow(R10K::Module).to receive(:new).with('puppet/test_module', subject.moduledir, '1.2.3', anything).and_call_original

      expect { subject.add_module('puppet/test_module', '1.2.3') }.to change { subject.modules }
      expect(subject.modules.collect(&:name)).to include('test_module')
    end

    it "should not accept Forge modules with a version comparison" do
      allow(R10K::Module).to receive(:new).with('puppet/test_module', subject.moduledir, '< 1.2.0', anything).and_call_original

      expect {
        subject.add_module('puppet/test_module', '< 1.2.0')
      }.to raise_error(RuntimeError, /module puppet\/test_module.*doesn't have an implementation/i)

      expect(subject.modules.collect(&:name)).not_to include('test_module')
    end

    it "should accept non-Forge modules with a hash arg" do
      module_opts = { git: 'git@example.com:puppet/test_module.git' }

      allow(R10K::Module).to receive(:new).with('puppet/test_module', subject.moduledir, module_opts, anything).and_call_original

      expect { subject.add_module('puppet/test_module', module_opts) }.to change { subject.modules }
      expect(subject.modules.collect(&:name)).to include('test_module')
    end

    it "should accept non-Forge modules with a valid relative :install_path option" do
      module_opts = {
        install_path: 'vendor',
        git: 'git@example.com:puppet/test_module.git',
      }

      allow(R10K::Module).to receive(:new).with('puppet/test_module', File.join(subject.basedir, 'vendor'), module_opts, anything).and_call_original

      expect { subject.add_module('puppet/test_module', module_opts) }.to change { subject.modules }
      expect(subject.modules.collect(&:name)).to include('test_module')
    end

    it "should accept non-Forge modules with a valid absolute :install_path option" do
      install_path = File.join(subject.basedir, 'vendor')

      module_opts = {
        install_path: install_path,
        git: 'git@example.com:puppet/test_module.git',
      }

      allow(R10K::Module).to receive(:new).with('puppet/test_module', install_path, module_opts, anything).and_call_original

      expect { subject.add_module('puppet/test_module', module_opts) }.to change { subject.modules }
      expect(subject.modules.collect(&:name)).to include('test_module')
    end

    it "should reject non-Forge modules with an invalid relative :install_path option" do
      module_opts = {
        install_path: '../../vendor',
        git: 'git@example.com:puppet/test_module.git',
      }

      allow(R10K::Module).to receive(:new).with('puppet/test_module', File.join(subject.basedir, 'vendor'), module_opts, anything).and_call_original

      expect { subject.add_module('puppet/test_module', module_opts) }.to raise_error(R10K::Error, /cannot manage content.*is not within/i).and not_change { subject.modules }
    end

    it "should reject non-Forge modules with an invalid absolute :install_path option" do
      module_opts = {
        install_path: '/tmp/mydata/vendor',
        git: 'git@example.com:puppet/test_module.git',
      }

      allow(R10K::Module).to receive(:new).with('puppet/test_module', File.join(subject.basedir, 'vendor'), module_opts, anything).and_call_original

      expect { subject.add_module('puppet/test_module', module_opts) }.to raise_error(R10K::Error, /cannot manage content.*is not within/i).and not_change { subject.modules }
    end
  end

  describe "#purge_exclusions" do
    let(:managed_dirs) { ['dir1', 'dir2'] }

    before(:each) do
      allow(subject).to receive(:managed_directories).and_return(managed_dirs)
    end

    it "includes managed_directories" do
      expect(subject.purge_exclusions).to match_array(managed_dirs)
    end

    context "when belonging to an environment" do
      let(:env_contents) { ['env1', 'env2' ] }

      before(:each) do
        mock_env = double(:environment, desired_contents: env_contents)
        allow(subject).to receive(:environment).and_return(mock_env)
      end

      it "includes environment's desired_contents" do
        expect(subject.purge_exclusions).to match_array(managed_dirs + env_contents)
      end
    end
  end

  describe "evaluating a Puppetfile" do
    def expect_wrapped_error(orig, pf_path, wrapped_error, pf_dirname)
      expect(orig).to be_a_kind_of(R10K::Error)
      expect(orig.message).to eq("#{pf_dirname}: Failed to evaluate #{pf_path}")
      expect(orig.original).to be_a_kind_of(wrapped_error)
    end

    it "wraps and re-raises syntax errors" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'invalid-syntax')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect {
        subject.load!
      }.to raise_error do |e|
        expect_wrapped_error(e, pf_path, SyntaxError, File.basename(path))
      end
    end

    it "wraps and re-raises load errors" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'load-error')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect {
        subject.load!
      }.to raise_error do |e|
        expect_wrapped_error(e, pf_path, LoadError, File.basename(path))
      end
    end

    it "wraps and re-raises argument errors" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'argument-error')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect {
        subject.load!
      }.to raise_error do |e|
        expect_wrapped_error(e, pf_path, ArgumentError, File.basename(path))
      end
    end

    it "accepts a forge module with a version" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'valid-forge-with-version')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect { subject.load! }.not_to raise_error
    end

    it "accepts a forge module without a version" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'valid-forge-without-version')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect { subject.load! }.not_to raise_error
    end
  end

  describe "accepting a visitor" do
    it "passes itself to the visitor" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit).with(:puppetfile, subject)
      subject.accept(visitor)
    end

    it "passes the visitor to each module if the visitor yields" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit) do |type, other, &block|
        expect(type).to eq :puppetfile
        expect(other).to eq subject
        block.call
      end

      mod1 = spy('module')
      expect(mod1).to receive(:accept).with(visitor)
      mod2 = spy('module')
      expect(mod2).to receive(:accept).with(visitor)

      expect(subject).to receive(:modules).and_return([mod1, mod2])
      subject.accept(visitor)
    end
  end
end
