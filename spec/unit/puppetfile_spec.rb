require 'spec_helper'
require 'r10k/puppetfile'

describe R10K::Puppetfile do

  subject do
    described_class.new(
      '/some/nonexistent/basedir',
      nil,
      nil,
      'Puppetfile.r10k'
    )
  end

  describe "a custom puppetfile Puppetfile.r10k" do
    it "is the basedir joined with '/Puppetfile.r10k' path" do
      expect(subject.puppetfile_path).to eq '/some/nonexistent/basedir/Puppetfile.r10k'
    end
  end

end

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

  describe "the default puppetfile" do
    it "is the basedir joined with '/Puppetfile' path" do
      expect(subject.puppetfile_path).to eq '/some/nonexistent/basedir/Puppetfile'
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

    it "groups modules by vcs cache location" do
      module_opts = { install_path: File.join(subject.basedir, 'vendor') }
      opts1 = module_opts.merge(git: 'git@example.com:puppet/test_module.git')
      opts2 = module_opts.merge(git: 'git@example.com:puppet/test_module_c.git')
      sanitized_name1 = "git@example.com-puppet-test_module.git"
      sanitized_name2 = "git@example.com-puppet-test_module_c.git"

      subject.add_module('puppet/test_module_a', opts1)
      subject.add_module('puppet/test_module_b', opts1)
      subject.add_module('puppet/test_module_c', opts2)
      subject.add_module('puppet/test_module_d', '1.2.3')

      mods_by_cachedir = subject.modules_by_vcs_cachedir

      expect(mods_by_cachedir[:none].length).to be 1
      expect(mods_by_cachedir[sanitized_name1].length).to be 2
      expect(mods_by_cachedir[sanitized_name2].length).to be 1
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
    def expect_wrapped_error(orig, pf_path, wrapped_error)
      expect(orig).to be_a_kind_of(R10K::Error)
      expect(orig.message).to eq("Failed to evaluate #{pf_path}")
      expect(orig.original).to be_a_kind_of(wrapped_error)
    end

    it "wraps and re-raises syntax errors" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'invalid-syntax')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect {
        subject.load!
      }.to raise_error do |e|
        expect_wrapped_error(e, pf_path, SyntaxError)
      end
    end

    it "wraps and re-raises load errors" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'load-error')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect {
        subject.load!
      }.to raise_error do |e|
        expect_wrapped_error(e, pf_path, LoadError)
      end
    end

    it "wraps and re-raises argument errors" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'argument-error')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect {
        subject.load!
      }.to raise_error do |e|
        expect_wrapped_error(e, pf_path, ArgumentError)
      end
    end

    it "rejects Puppetfiles with duplicate module names" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'duplicate-module-error')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect {
        subject.load!
      }.to raise_error(R10K::Error, /Puppetfiles cannot contain duplicate module names/i)
    end

    it "wraps and re-raises name errors" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'name-error')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect {
        subject.load!
      }.to raise_error do |e|
        expect_wrapped_error(e, pf_path, NameError)
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

    it "creates a git module and applies the default branch sepcified in the Puppetfile" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'default-branch-override')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      expect { subject.load! }.not_to raise_error
      git_module = subject.modules[0]
      expect(git_module.default_ref).to eq 'here_lies_the_default_branch'
    end

    it "creates a git module and applies the provided default_branch_override" do
      path = File.join(PROJECT_ROOT, 'spec', 'fixtures', 'unit', 'puppetfile', 'default-branch-override')
      pf_path = File.join(path, 'Puppetfile')
      subject = described_class.new(path)
      default_branch_override = 'default_branch_override_name'
      expect { subject.load!(default_branch_override) }.not_to raise_error
      git_module = subject.modules[0]
      expect(git_module.default_ref).to eq default_branch_override
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

      expect(subject).to receive(:modules_by_vcs_cachedir).and_return({none: [mod1, mod2]})
      subject.accept(visitor)
    end

    it "creates a thread pool to visit concurrently if pool_size setting is greater than one" do
      pool_size = 3

      subject.settings[:pool_size] = pool_size

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

      expect(subject).to receive(:modules_by_vcs_cachedir).and_return({none: [mod1, mod2]})

      expect(Thread).to receive(:new).exactly(pool_size).and_call_original
      expect(Queue).to receive(:new).and_call_original

      subject.accept(visitor)
    end

    it "Creates queues of modules grouped by cachedir" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit) do |type, other, &block|
        expect(type).to eq :puppetfile
        expect(other).to eq subject
        block.call
      end

      mod1 = spy('module1')
      mod2 = spy('module2')
      mod3 = spy('module3')
      mod4 = spy('module4')
      mod5 = spy('module4')
      mod6 = spy('module5')

      expect(subject).to receive(:modules_by_vcs_cachedir)
        .and_return({:none => [mod1, mod2],
                     "foo-cachedir" => [mod3, mod4],
                     "bar-cachedir" => [mod5, mod6]})

      queue = subject.modules_queue(visitor)
      expect(queue.length).to be 4
      queue_array = 4.times.map { queue.pop }
      expect(queue_array).to match_array([[mod1], [mod2], [mod3, mod4], [mod5, mod6]])
    end
  end
end
