require 'spec_helper'
require 'r10k/git'

describe R10K::Git::WorkingDir do
  include_context "fail on execution"

  describe "initializing" do
    it "generates a new cache for the remote" do
      wd = described_class.new('master', 'git://github.com/adrienthebo/r10k-fixture-repo', '/some/nonexistent/dir')
      wd.cache.should be_kind_of R10K::Git::Cache
    end

    it "uses the provided ref as the dirname when no dirname is given" do
      wd = described_class.new('master', 'git://github.com/adrienthebo/r10k-fixture-repo', '/some/nonexistent/dir')
      expect(wd.dirname).to eq('master')
    end

    it "uses an explicit dirname when given" do
      wd = described_class.new('master', 'git://github.com/adrienthebo/r10k-fixture-repo', '/some/nonexistent/dir', 'mydir')
      expect(wd.dirname).to eq('mydir')
    end
  end

  describe "synchronizing the working directory" do
    subject { described_class.new('master', 'git://github.com/adrienthebo/r10k-fixture-repo', '/some/nonexistent/dir') }
    it "clones the repository when the repository doesn't exist" do
      expect(subject).to receive(:cloned?).and_return false
      expect(subject).to receive(:clone)
      subject.sync
    end

    it "updates the repository when the repository already exists" do
      expect(subject).to receive(:cloned?).and_return true
      expect(subject).to receive(:update)
      subject.sync
    end
  end

  describe "when cloning a new repository" do
    subject { described_class.new('master', 'git://github.com/adrienthebo/r10k-fixture-repo', '/some/nonexistent/dir') }

    before do
      allow(subject).to receive(:cloned?).and_return false
    end

    it "updates the cache before cloning" do
      expect(subject.cache).to receive(:sync)
      allow(subject).to receive(:git)
      allow(subject).to receive(:checkout)
      subject.sync
    end

    it "clones the repository and uses the cache git dir as an object reference" do
      allow(subject.cache).to receive(:sync)
      expect(subject).to receive(:git).with(['clone', '--reference', subject.cache.git_dir,
                                             'git://github.com/adrienthebo/r10k-fixture-repo',
                                             '/some/nonexistent/dir/master'])
      expect(subject).to receive(:git).with(['remote', 'add', 'cache', subject.cache.git_dir],
                                            an_instance_of(Hash))

      expect(subject).to receive(:git).with(['fetch', 'cache'], an_instance_of(Hash))
      allow(subject).to receive(:checkout)
      subject.sync
    end

    it 'checks out the specific ref after the clone' do
      allow(subject.cache).to receive(:sync)
      allow(subject).to receive(:git)
      expect(subject).to receive(:checkout)
      subject.sync
    end
  end

  describe "updating an existing repository" do
    subject { described_class.new('master', 'git://github.com/adrienthebo/r10k-fixture-repo', '/some/nonexistent/dir') }

    before do
      allow(subject).to receive(:cloned?).and_return true
    end

    it "updates the remotes when they are out of sync" do
      allow(subject).to receive(:ref_needs_fetch?).and_return false
      allow(subject).to receive(:needs_checkout?).and_return false

      expect(subject).to receive(:update_remotes?).and_return true
      expect(subject).to receive(:update_remotes)

      subject.sync
    end

    it "updates the cache when the ref requires an update" do
      allow(subject).to receive(:update_remotes?).and_return false

      expect(subject).to receive(:ref_needs_fetch?).and_return true
      expect(subject).to receive(:fetch_from_cache)
      expect(subject).to receive(:checkout).with(an_instance_of(R10K::Git::Ref))

      subject.sync
    end

    it "checks out the ref when the wrong commit is checked out" do
      allow(subject).to receive(:update_remotes?).and_return false
      allow(subject).to receive(:ref_needs_fetch?).and_return false

      expect(subject).to receive(:needs_checkout?).and_return true
      expect(subject).to receive(:checkout).with(an_instance_of(R10K::Git::Ref))

      subject.sync
    end

    it "doesn't update the repo when everything is in sync" do
      allow(subject).to receive(:update_remotes?).and_return false
      allow(subject).to receive(:ref_needs_fetch?).and_return false
      allow(subject).to receive(:needs_checkout?).and_return false

      expect(subject).to_not receive(:checkout)

      subject.sync
    end
  end
end
