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
    it "updates all modules when creating a new environment" do
      allow(working_dir).to receive(:is_svn?).and_return(false)
      expect(working_dir).to receive(:checkout)
      expect(subject).to receive(:sync_modules)
      subject.sync
    end

    it "does not update all modules when updating an existing environment" do
      allow(working_dir).to receive(:is_svn?).and_return(true)
      expect(working_dir).to receive(:update)
      expect(subject).to_not receive(:sync_modules)
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
      expect(subject.puppetfile).to receive(:load)
      expect(subject.puppetfile).to receive(:modules).and_return [:modules]
      expect(subject.modules).to eq([:modules])
    end
  end
end
