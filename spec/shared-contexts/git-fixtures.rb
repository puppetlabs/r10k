require 'archive/tar/minitar'
require 'tmpdir'

shared_context "Git integration" do

  # Use tmpdir for cached git repositories

  before(:all) do
    @old_cache_root = R10K::Git::Cache.settings[:cache_root]
    R10K::Git::Cache.settings[:cache_root] = Dir.mktmpdir
  end

  after(:all) do
    FileUtils.remove_entry_secure(R10K::Git::Cache.settings[:cache_root])
    R10K::Git::Cache.settings[:cache_root] = @old_cache_root
  end

  # Create a mutable path for remote repositories

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'integration', 'git')
  end

  def remote_path
    @remote_path
  end

  def populate_remote_path
    Archive::Tar::Minitar.unpack(File.join(fixture_path, 'puppet-boolean-bare.tar'), remote_path)
  end

  def clear_remote_path
    FileUtils.remove_entry_secure(remote_path)
  end

  before(:all) do
    @remote_path = Dir.mktmpdir
    populate_remote_path
  end

  after(:all) do
    clear_remote_path
    @remote_path = nil
  end

  let(:remote) { Pathname.new(File.join(remote_path, 'puppet-boolean.git')).realpath.to_s }

  # Create a temp path for the git basedir and clean it up when finished

  let(:basedir) { Dir.mktmpdir }

  after do
    FileUtils.remove_entry_secure(basedir)
  end
end
