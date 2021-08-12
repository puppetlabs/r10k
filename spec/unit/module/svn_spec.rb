require 'spec_helper'

require 'r10k/module/svn'

describe R10K::Module::SVN do

  include_context 'fail on execution'

  describe "determining it implements a Puppetfile mod" do
    it "implements mods with the :svn hash key" do
      implements = described_class.implement?('r10k-fixture-repo', :svn => 'https://github.com/adrienthebo/r10k-fixture-repo')
      expect(implements).to eq true
    end
  end

  describe "path variables" do
    it "uses the module name as the name" do
      svn = described_class.new('foo', '/moduledir', :rev => 'r10')
      expect(svn.name).to eq 'foo'
      expect(svn.owner).to be_nil
      expect(svn.dirname).to eq '/moduledir'
      expect(svn.path).to eq Pathname.new('/moduledir/foo')
    end

    it "does not include the owner in the path" do
      svn = described_class.new('bar/foo', '/moduledir', :rev => 'r10')
      expect(svn.name).to eq 'foo'
      expect(svn.owner).to eq 'bar'
      expect(svn.dirname).to eq '/moduledir'
      expect(svn.path).to eq Pathname.new('/moduledir/foo')
    end
  end


  describe "instantiating based on Puppetfile configuration" do
    it "can specify a revision with the :rev key" do
      svn = described_class.new('foo', '/moduledir', :rev => 'r10')
      expect(svn.expected_revision).to eq 'r10'
    end

    it "can specify a revision with the :revision key" do
      svn = described_class.new('foo', '/moduledir', :revision => 'r10')
      expect(svn.expected_revision).to eq 'r10'
    end
  end

  describe "properties" do
    subject { described_class.new('foo', '/moduledir', :svn => 'https://github.com/adrienthebo/r10k-fixture-repo', :rev => 123) }

    it "sets the module type to :svn" do
      expect(subject.properties).to include(:type => :svn)
    end

    it "sets the expected version" do
      expect(subject.properties).to include(:expected => 123)
    end

    it "sets the actual version to the revision when the revision is available" do
      expect(subject.working_dir).to receive(:revision).and_return(12)
      expect(subject.properties).to include(:actual => 12)
    end

    it "sets the actual version (unresolvable) when the revision is unavailable" do
      expect(subject.working_dir).to receive(:revision).and_raise(ArgumentError)
      expect(subject.properties).to include(:actual => "(unresolvable)")
    end
  end

  describe "determining the status" do
    subject { described_class.new('foo', '/moduledir', :svn => 'https://github.com/adrienthebo/r10k-fixture-repo', :rev => 123) }

    let(:working_dir) { double 'working_dir' }

    before do
      allow(R10K::SVN::WorkingDir).to receive(:new).and_return working_dir
    end

    it "is :absent if the module directory is absent" do
      allow(subject).to receive(:exist?).and_return false

      expect(subject.status).to eq :absent
    end

    it "is :mismatched if the directory is present but not an SVN repo" do
      allow(subject).to receive(:exist?).and_return true

      allow(working_dir).to receive(:is_svn?).and_return false

      expect(subject.status).to eq :mismatched
    end

    it "is mismatched when the wrong SVN URL is checked out" do
      allow(subject).to receive(:exist?).and_return true

      allow(working_dir).to receive(:is_svn?).and_return true
      allow(working_dir).to receive(:url).and_return 'svn://nope/trunk'

      expect(subject.status).to eq :mismatched
    end

    it "is :outdated when the expected rev doesn't match the actual rev" do
      allow(subject).to receive(:exist?).and_return true

      allow(working_dir).to receive(:is_svn?).and_return true
      allow(working_dir).to receive(:url).and_return 'https://github.com/adrienthebo/r10k-fixture-repo'
      allow(working_dir).to receive(:revision).and_return 99

      expect(subject.status).to eq :outdated
    end

    it "is :insync if all other conditions are satisfied" do
      allow(subject).to receive(:exist?).and_return true

      allow(working_dir).to receive(:is_svn?).and_return true
      allow(working_dir).to receive(:url).and_return 'https://github.com/adrienthebo/r10k-fixture-repo'
      allow(working_dir).to receive(:revision).and_return 123

      expect(subject.status).to eq :insync
    end
  end

  describe 'the default spec dir' do
    let(:module_org) { "coolorg" }
    let(:module_name) { "coolmod" }
    let(:title) { "#{module_org}-#{module_name}" }
    let(:dirname) { Pathname.new(Dir.mktmpdir) }
    let(:spec_path) { dirname + module_name + 'spec' }
    subject { described_class.new(title, dirname, {}) }

    it 'is kept by default' do

      FileUtils.mkdir_p(spec_path)
      expect(subject).to receive(:status).and_return(:absent)
      expect(subject).to receive(:install).and_return(nil)
      subject.sync
      expect(Dir.exist?(spec_path)).to eq true
    end
  end

  describe "synchronizing" do

    subject { described_class.new('foo', '/moduledir', :svn => 'https://github.com/adrienthebo/r10k-fixture-repo', :rev => 123) }

    before do
      allow(File).to receive(:directory?).with('/moduledir').and_return true
    end

    describe "and the state is :absent" do
      before { allow(subject).to receive(:status).and_return :absent }

      it "installs the SVN module" do
        expect(subject).to receive(:install)
        subject.sync
      end
    end

    describe "and the state is :mismatched" do
      before { allow(subject).to receive(:status).and_return :mismatched }

      it "reinstalls the module" do
        expect(subject).to receive(:reinstall)

        subject.sync
      end

      it "removes the existing directory" do
        expect(subject.path).to receive(:rmtree)
        allow(subject).to receive(:install)

        subject.sync
      end
    end

    describe "and the state is :outdated" do
      before { allow(subject).to receive(:status).and_return :outdated }

      it "upgrades the repository" do
        expect(subject).to receive(:update)

        subject.sync
      end
    end

    describe "and the state is :insync" do
      before { allow(subject).to receive(:status).and_return :insync }

      it "doesn't change anything" do
        expect(subject).to receive(:install).never
        expect(subject).to receive(:reinstall).never
        expect(subject).to receive(:update).never

        subject.sync
      end
    end
  end
end
