require 'archive/tar/minitar'
require 'tmpdir'

shared_context "Git integration" do

  before(:all) do
    @old_cache_root = R10K::Git::Cache.settings[:cache_root]
    R10K::Git::Cache.settings[:cache_root] = Dir.mktmpdir
  end

  after(:all) do
    FileUtils.remove_entry_secure(R10K::Git::Cache.settings[:cache_root])
    R10K::Git::Cache.settings[:cache_root] = @old_cache_root
  end


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
end
