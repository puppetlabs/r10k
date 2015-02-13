require 'spec_helper'
require 'r10k/git/thin_repository'
require 'r10k/git/stateful_repository'

require 'tmpdir'

describe R10K::Git::StatefulRepository do
  include_context 'Git integration'

  let(:remote) { File.join(remote_path, 'puppet-boolean.git') }
  let(:basedir) { Dir.mktmpdir }
  let(:dirname) { 'working-repo' }

  let(:thinrepo) { R10K::Git::ThinRepository.new(basedir, dirname) }

  subject { described_class.new('0.9.x', remote, basedir, dirname) }

  describe 'status' do
    it "is absent when the directory does not exist" do
      expect(subject.status).to eq :absent
    end

    it "is mismatched when the directory is not a git repository" do
      thinrepo.path.mkdir
      expect(subject.status).to eq :mismatched
    end

    it "is mismatched when the repository doesn't match the desired remote" do
      thinrepo.clone(remote, {:ref => '1.0.0'})
      allow(subject.repo).to receive(:origin).and_return('http://some.site/repo.git')
      expect(subject.status).to eq :mismatched
    end

    it "is outdated when the wrong ref is checked out" do
      thinrepo.clone(remote, {:ref => '1.0.0'})
      expect(subject.status).to eq :outdated
    end

    it "is insync if the right ref is checked out" do
      thinrepo.clone(remote, {:ref => 'origin/0.9.x'})
      expect(subject.status).to eq :insync
    end
  end

  describe "syncing" do
    it "creates the repo when absent" do
      subject.sync
      expect(subject.status).to eq :insync
    end

    it "removes and recreates the repo when mismatched" do
      thinrepo.path.mkdir
      subject.sync
      expect(subject.status).to eq :insync
    end

    it "updates the repository when out of date" do
      thinrepo.clone(remote, {:ref => '1.0.0'})
      subject.sync
      expect(subject.status).to eq :insync
    end
  end
end
