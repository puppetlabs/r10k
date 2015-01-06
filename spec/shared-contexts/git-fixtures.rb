require 'archive/tar/minitar'
require 'tmpdir'

shared_context "Git integration" do

  def fixture_path
    File.join(PROJECT_ROOT, 'spec', 'fixtures', 'integration', 'git')
  end

  def remote_path
    @remote_path
  end

  def setup_remote_path
    @remote_path = Dir.mktmpdir
  end

  def teardown_remote_path
    FileUtils.remove_entry_secure(@remote_path)
    @remote_path = nil
  end

  def fixture_bare_tar
    File.join(fixture_path, 'puppet-boolean-bare.tar')
  end

  before(:all) do
    setup_remote_path
    Archive::Tar::Minitar.unpack(fixture_bare_tar, remote_path)
  end

  after(:all) do
    teardown_remote_path
    @remote_path = nil
  end
end
