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

  describe "instantiating based on Puppetfile configuration" do
    it "can specify a revision with the :rev key" do
      svn = described_class.new('foo', '/moduledir', :rev => 'r10')
      expect(svn.expected_revision).to eq 'r10'
    end

    it "can specify a revision with the :revision key" do
      svn = described_class.new('foo', '/moduledir', :revision => 'r10')
      expect(svn.expected_revision).to eq 'r10'
    end

    it "can specify a path within the SVN repo" do
      svn = described_class.new('foo', '/moduledir', :svn_path => 'branches/something/foo')
      expect(svn.svn_path).to eq 'branches/something/foo'
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

  describe "and the expected version is :latest" do
    it "sets the expected version based on the latest SVN revision"
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
        expect(subject.full_path).to receive(:unlink)
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
