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

  context "checking out a specific SHA" do
    let(:_rugged_repo) { double("Repository") }

    before do
      subject.clone(remote)
      allow(subject).to receive(:with_repo).and_yield(_rugged_repo)
      allow(subject).to receive(:resolve).and_return("157011a4eaa27f1202a9d94335ee4876b26d377e")
    end

    describe "with force" do
      it "does not receive a checkout call" do
        expect(_rugged_repo).to_not receive(:checkout)
        expect(_rugged_repo).to receive(:reset)
        subject.checkout("157011a4eaa27f1202a9d94335ee4876b26d377e", {:force => true})
      end
    end

    describe "without force" do
      it "does receive a checkout call" do
        expect(_rugged_repo).to receive(:checkout)
        expect(_rugged_repo).to_not receive(:reset)
        subject.checkout("157011a4eaa27f1202a9d94335ee4876b26d377e", {:force => false})
      end
    end
  end
end
