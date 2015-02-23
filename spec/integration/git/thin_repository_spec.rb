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

  it_behaves_like "a git thin repository"
end
