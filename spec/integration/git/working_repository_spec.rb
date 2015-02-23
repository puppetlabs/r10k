require 'spec_helper'
require 'r10k/git/working_repository'

describe R10K::Git::WorkingRepository do
  include_context 'Git integration'

  let(:remote) { File.realpath(File.join(remote_path, 'puppet-boolean.git')) }
  let(:basedir) { Dir.mktmpdir }
  let(:dirname) { 'working-repo' }

  after do
    FileUtils.remove_entry_secure(basedir)
  end

  subject { described_class.new(basedir, dirname) }

  it_behaves_like 'a git repository'
  it_behaves_like 'a git working repository'
end
