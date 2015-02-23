require 'spec_helper'
require 'r10k/git/shellgit/thin_repository'

describe R10K::Git::ShellGit::ThinRepository do
  include_context 'Git integration'

  let(:dirname) { 'working-repo' }

  subject { described_class.new(basedir, dirname) }

  let(:cacherepo) { R10K::Git::Cache.generate(remote) }

  it_behaves_like "a git thin repository"
end
