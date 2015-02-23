require 'spec_helper'
require 'r10k/git/shellgit/thin_repository'
require 'r10k/git/stateful_repository'

describe R10K::Git::StatefulRepository do
  include_context 'Git integration'

  let(:dirname) { 'working-repo' }

  let(:thinrepo) { R10K::Git::ShellGit::ThinRepository.new(basedir, dirname) }
  let(:cacherepo) { R10K::Git::Cache.generate(remote) }

  subject { described_class.new('0.9.x', remote, basedir, dirname) }

  describe 'status' do
    describe "when the directory does not exist" do
      it "is absent" do
        expect(subject.status).to eq :absent
      end
    end

    describe "when the directory is not a git repository" do
      it "is mismatched" do
        thinrepo.path.mkdir
        expect(subject.status).to eq :mismatched
      end
    end

    describe "when the repository doesn't match the desired remote" do
      it "is mismatched" do
        thinrepo.clone(remote, {:ref => '1.0.0'})
        allow(subject.repo).to receive(:origin).and_return('http://some.site/repo.git')
        expect(subject.status).to eq :mismatched
      end
    end

    describe "when the wrong ref is checked out" do
      it "is outdated" do
        thinrepo.clone(remote, {:ref => '1.0.0'})
        expect(subject.status).to eq :outdated
      end
    end

    describe "when the ref is a branch and the cache is not synced" do
      it "is outdated" do
        thinrepo.clone(remote, {:ref => '0.9.x'})
        cacherepo.reset!
        expect(subject.status).to eq :outdated
      end
    end

    describe "when the ref can't be resolved" do
      subject { described_class.new('1.1.x', remote, basedir, dirname) }

      it "is outdated" do
        thinrepo.clone(remote, {:ref => '0.9.x'})
        expect(subject.status).to eq :outdated
      end
    end

    describe "if the right ref is checked out" do
      it "is insync" do
        thinrepo.clone(remote, {:ref => 'origin/0.9.x'})
        expect(subject.status).to eq :insync
      end
    end
  end

  describe "syncing" do

    describe "when the ref is unresolvable" do
      subject { described_class.new('1.1.x', remote, basedir, dirname) }

      it "raises an error" do
        expect {
          subject.sync
        }.to raise_error(R10K::Git::UnresolvableRefError)
      end
    end

    describe "when the repo is absent" do
      it "creates the repo" do
        subject.sync
        expect(subject.status).to eq :insync
      end
    end

    describe "when the repo is mismatched" do
      it "removes and recreates the repo" do
        thinrepo.path.mkdir
        subject.sync
        expect(subject.status).to eq :insync
      end
    end

    describe "when the repo is out of date" do
      it "updates the repository" do
        thinrepo.clone(remote, {:ref => '1.0.0'})
        subject.sync
        expect(subject.status).to eq :insync
      end
    end
  end
end
