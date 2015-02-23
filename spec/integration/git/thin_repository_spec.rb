require 'spec_helper'
require 'r10k/git/thin_repository'

require 'tmpdir'

describe R10K::Git::ThinRepository do
  include_context 'Git integration'

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
