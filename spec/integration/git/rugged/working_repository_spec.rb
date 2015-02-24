require 'spec_helper'
require 'r10k/git/rugged/working_repository'

describe R10K::Git::Rugged::WorkingRepository do
  include_context 'Git integration'

  let(:dirname) { 'working-repo' }

  subject { described_class.new(basedir, dirname) }

  it_behaves_like 'a git repository'
  it_behaves_like 'a git working repository'
end
