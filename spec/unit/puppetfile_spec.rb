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

  describe "the default puppetfile" do
    it "is the basedir joined with '/Puppetfile' path" do
      expect(subject.puppetfile_path).to eq '/some/nonexistent/basedir/Puppetfile'
    end
  end

  describe "a custom puppetfile Puppetfile.r10k" do
    before { R10K::Puppetfile.settings[:puppetfile] = "Puppetfile.r10k" }
    after { R10K::Puppetfile.settings.reset! }
    it "is the basedir joined with '/Puppetfile.r10k' path" do
      expect(subject.puppetfile_path).to eq '/some/nonexistent/basedir/Puppetfile.r10k'
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
      allow(R10K::Module).to receive(:new).with('puppet/test_module', subject.moduledir, '1.2.3').and_call_original

      expect { subject.add_module('puppet/test_module', '1.2.3') }.to change { subject.modules }
      expect(subject.modules.collect(&:name)).to include('test_module')
    end

    it "should accept non-Forge modules with a hash arg" do
      module_opts = { git: 'git@example.com:puppet/test_module.git' }

      allow(R10K::Module).to receive(:new).with('puppet/test_module', subject.moduledir, module_opts).and_call_original

      expect { subject.add_module('puppet/test_module', module_opts) }.to change { subject.modules }
      expect(subject.modules.collect(&:name)).to include('test_module')
    end

    it "should accept non-Forge modules with a valid relative :install_path option" do
      module_opts = {
        install_path: 'vendor',
        git: 'git@example.com:puppet/test_module.git',
      }

      allow(R10K::Module).to receive(:new).with('puppet/test_module', File.join(subject.basedir, 'vendor'), module_opts).and_call_original

      expect { subject.add_module('puppet/test_module', module_opts) }.to change { subject.modules }
      expect(subject.modules.collect(&:name)).to include('test_module')
    end

    it "should accept non-Forge modules with a valid absolute :install_path option" do
      install_path = File.join(subject.basedir, 'vendor')

      module_opts = {
        install_path: install_path,
        git: 'git@example.com:puppet/test_module.git',
      }

      allow(R10K::Module).to receive(:new).with('puppet/test_module', install_path, module_opts).and_call_original

      expect { subject.add_module('puppet/test_module', module_opts) }.to change { subject.modules }
      expect(subject.modules.collect(&:name)).to include('test_module')
    end

    it "should reject non-Forge modules with an invalid relative :install_path option" do
      module_opts = {
        install_path: '../../vendor',
        git: 'git@example.com:puppet/test_module.git',
      }

      allow(R10K::Module).to receive(:new).with('puppet/test_module', File.join(subject.basedir, 'vendor'), module_opts).and_call_original

      expect { subject.add_module('puppet/test_module', module_opts) }.to raise_error(R10K::Error, /cannot manage content.*is not within/i).and not_change { subject.modules }
    end

    it "should reject non-Forge modules with an invalid absolute :install_path option" do
      module_opts = {
        install_path: '/tmp/mydata/vendor',
        git: 'git@example.com:puppet/test_module.git',
      }

      allow(R10K::Module).to receive(:new).with('puppet/test_module', File.join(subject.basedir, 'vendor'), module_opts).and_call_original

      expect { subject.add_module('puppet/test_module', module_opts) }.to raise_error(R10K::Error, /cannot manage content.*is not within/i).and not_change { subject.modules }
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
