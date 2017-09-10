require 'spec_helper'
require 'r10k/environment'

describe R10K::Environment::SVN do

  subject do
    described_class.new(
      'myenv',
      '/some/nonexistent/environmentdir',
      'svn-dirname',
      {
        :remote => 'https://svn-server.site/svn-repo/trunk'
      }
    )
  end

  let(:working_dir) { subject.working_dir }

  describe "storing attributes" do
    it "can return the environment name" do
      expect(subject.name).to eq 'myenv'
    end

    it "can return the environment basedir" do
      expect(subject.basedir).to eq '/some/nonexistent/environmentdir'
    end

    it "can return the environment dirname" do
      expect(subject.dirname).to eq 'svn-dirname'
    end

    it "can return the environment remote" do
      expect(subject.remote).to eq 'https://svn-server.site/svn-repo/trunk'
    end
  end

  describe "synchronizing the environment" do
    it "checks out the working directory when creating a new environment" do
      allow(working_dir).to receive(:is_svn?).and_return(false)
      expect(working_dir).to receive(:checkout)
      subject.sync
    end

    it "updates the working directory when updating an existing environment" do
      allow(working_dir).to receive(:is_svn?).and_return(true)
      expect(working_dir).to receive(:update)
      subject.sync
    end
  end

  describe "generating a puppetfile for the environment" do
    let(:puppetfile) { subject.puppetfile }

    it "creates a puppetfile at the full path to the environment" do
      expect(puppetfile.basedir).to eq '/some/nonexistent/environmentdir/svn-dirname'
    end

    it "sets the moduledir to 'modules' relative to the environment path" do
      expect(puppetfile.moduledir).to eq '/some/nonexistent/environmentdir/svn-dirname/modules'
    end

    it "sets the puppetfile path to 'Puppetfile' relative to the environment path" do
      expect(puppetfile.puppetfile_path).to eq '/some/nonexistent/environmentdir/svn-dirname/Puppetfile'
    end
  end

  describe "enumerating modules" do
    it "loads the Puppetfile and returns modules in that puppetfile" do
      expect(subject.puppetfile).to receive(:modules).and_return [:modules]
      expect(subject.modules).to eq([:modules])
    end
  end

  describe "determining the status" do
    it "is absent if the working directory is absent" do
      expect(subject.path).to receive(:exist?).and_return(false)
      expect(subject.status).to eq :absent
    end

    it "is mismatched if the working directory is not an SVN repo" do
      expect(subject.path).to receive(:exist?).and_return(true)
      expect(working_dir).to receive(:is_svn?).and_return(false)
      expect(subject.status).to eq :mismatched
    end

    it "is mismatched if the working directory remote doesn't match the expected remote" do
      expect(subject.path).to receive(:exist?).and_return(true)
      expect(working_dir).to receive(:is_svn?).and_return(true)
      expect(working_dir).to receive(:url).and_return 'https://svn-server.site/another-svn-repo/trunk'
      expect(subject.status).to eq :mismatched
    end

    it "is outdated when the the working directory has not synced" do
      expect(subject.path).to receive(:exist?).and_return(true)
      expect(working_dir).to receive(:is_svn?).and_return(true)
      expect(working_dir).to receive(:url).and_return 'https://svn-server.site/svn-repo/trunk'
      expect(subject.status).to eq :outdated
    end

    it "is insync when the working directory has been synced" do
      expect(subject.path).to receive(:exist?).and_return(true)
      expect(working_dir).to receive(:is_svn?).twice.and_return(true)
      expect(working_dir).to receive(:url).and_return 'https://svn-server.site/svn-repo/trunk'

      expect(working_dir).to receive(:update)

      subject.sync

      expect(subject.status).to eq :insync
    end
  end

  describe "environment signature" do
    it "returns the svn revision of the branch" do
      expect(working_dir).to receive(:revision).and_return '1337'
      expect(subject.signature).to eq '1337'
    end
  end

  describe "info hash" do
    let(:info_hash) { subject.info }

    before(:each) do
      expect(working_dir).to receive(:revision).and_return '1337'
    end

    it "includes name and signature" do
      expect(info_hash.keys).to include :name, :signature
      expect(info_hash).not_to have_value(nil)
    end
  end
end
