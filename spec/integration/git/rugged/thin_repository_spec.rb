require 'spec_helper'
require 'r10k/git/rugged/thin_repository'

describe R10K::Git::Rugged::ThinRepository, :if => R10K::Features.available?(:rugged) do
  include_context 'Git integration'

  let(:dirname) { 'working-repo' }

  let(:gitdirname) { '.git' }

  let(:cacherepo) { R10K::Git::Rugged::Cache.generate(remote) }

  subject { described_class.new(basedir, dirname, gitdirname, cacherepo) }

  it_behaves_like "a git thin repository"
end
