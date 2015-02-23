require 'spec_helper'
require 'r10k/git/bare_repository'

require 'tmpdir'

describe R10K::Git::BareRepository do

  include_context 'Git integration'

  let(:remote) { File.join(remote_path, 'puppet-boolean.git') }
  let(:basedir) { Dir.mktmpdir }
  let(:dirname) { 'bare-repo.git' }

  after do
    FileUtils.remove_entry_secure(basedir)
  end

  subject { described_class.new(basedir, dirname) }

  it_behaves_like 'a git repository'
  it_behaves_like 'a git bare repository'
end
