require 'spec_helper'
require 'r10k/git/rugged/working_repository'

describe R10K::Git::Rugged::WorkingRepository, :if => R10K::Features.available?(:rugged) do
  include_context 'Git integration'

  let(:dirname) { 'working-repo' }

  subject { described_class.new(basedir, dirname) }

  it_behaves_like 'a git repository'
  it_behaves_like 'a git working repository'

  describe "checking out an unresolvable ref" do
    it "raises an error indicating that the ref was unresolvable" do
      expect(subject).to receive(:resolve).with("unresolvable")
      expect {
        subject.checkout("unresolvable")
      }.to raise_error(R10K::Git::GitError, /Unable to check out unresolvable ref 'unresolvable'/)
    end
  end
end
