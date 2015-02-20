require 'spec_helper'
require 'r10k/git/thin_repository'

require 'tmpdir'

describe R10K::Git::ThinRepository do
  include_context 'Git integration'

  before(:all) do
    @old_cache_root = R10K::Git::Cache.settings[:cache_root]
    R10K::Git::Cache.settings[:cache_root] = Dir.mktmpdir
  end

  after(:all) do
    FileUtils.remove_entry_secure(R10K::Git::Cache.settings[:cache_root])
    R10K::Git::Cache.settings[:cache_root] = @old_cache_root
  end

  let(:remote) { File.join(remote_path, 'puppet-boolean.git') }
  let(:basedir) { Dir.mktmpdir }
  let(:dirname) { 'working-repo' }

  after do
    FileUtils.remove_entry_secure(basedir)
  end

  subject { described_class.new(basedir, dirname) }

  let(:cacherepo) { R10K::Git::Cache.generate(remote) }

  describe "cloning" do
    it "creates a working copy of the repo" do
      subject.clone(remote)
      expect(subject.exist?).to be_truthy
    end

    it "sets the remote origin url to the provided url" do
      subject.clone(remote)
      expect(subject.origin).to eq remote
    end

    it "sets the remote cache url to the path to the cache repo" do
      subject.clone(remote)
      expect(subject.cache).to eq cacherepo.git_dir.to_s
    end

    it "adds the cache repo to the alternates file" do
      subject.clone(remote)
      expect(subject.alternates.to_a).to eq [File.realpath(File.join(cacherepo.git_dir, 'objects'))]
    end
  end
end
