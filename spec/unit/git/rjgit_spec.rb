require 'spec_helper'
require 'r10k/util/platform'
require 'r10k/git/rjgit'

RSpec.describe R10K::Git::RJGit, :if => R10K::Util::Platform.jruby? do
  let(:repo_git) { double(:repo_git) }
  let(:repo) { instance_double(::RJGit::Repo, git: repo_git) }

  before(:each) do
    allow(::RJGit::Repo).to receive(:new).and_return(repo)
  end

  describe ".reset" do
    it "returns true on success" do
      expect(subject).to receive(:resolve_version).with('testref', anything).and_return('testsha')
      expect(repo_git).to receive(:reset).with('testsha', anything)

      expect(subject.reset('testref')).to eq(true)
    end

    it "raises R10K::Git::GitError with message when unable to resolve ref" do
      expect(subject).to receive(:resolve_version).with('testref', anything).and_return(nil)

      expect { subject.reset('testref') }.to raise_error(R10K::Git::GitError, /could not resolve/i)
    end

    it "raises R10K::Git::GitError with message on CheckoutConflictException" do
      expect(subject).to receive(:resolve_version).with('testref', anything).and_return('testsha')
      expect(repo_git).to receive(:reset).with('testsha', anything).and_raise(Java::OrgEclipseJgitApiErrors::CheckoutConflictException.new(['/foo/bar'], Java::OrgEclipseJgitErrors::CheckoutConflictException.new('/foo/bar')))

      expect { subject.reset('testref') }.to raise_error(R10K::Git::GitError, /conflict with file/i)
    end

    it "supports opts[:hard]" do
      expect(subject).to receive(:resolve_version).with('testref', anything).and_return('testsha')
      expect(repo_git).to receive(:reset).with('testsha', 'HARD')

      expect(subject.reset('testref', hard: true)).to eq(true)
    end
  end

  describe ".clean" do
    it "returns true on success" do
      expect(repo).to receive(:clean)

      expect(subject.clean()).to eq(true)
    end

    it "raises R10K::Git::GitError with message on NoWorkTreeException" do
      expect(repo).to receive(:clean).and_raise(Java::OrgEclipseJgitErrors::NoWorkTreeException.new)

      expect { subject.clean() }.to raise_error(R10K::Git::GitError, /neither a working tree.*nor an index/i)
    end

    it "supports opts[:excludes]" do
      pending("jgit does not support exclude list for git-clean")
      fail
    end
  end

  describe ".rev_parse" do
    it "returns sha without whitespace on success" do
      to_resolve = 'branch_name'
      expect(repo).to receive(:commits).with(to_resolve).and_return([double(:commit, id: '123abc')])

      expect(subject.rev_parse(to_resolve)).to eq('123abc')
    end

    it "raises R10K::Git::GitError with message when unable to resolve ref" do
      to_resolve = 'branch_name'
      expect(repo).to receive(:commits).with(to_resolve).and_return([])

      expect { subject.rev_parse(to_resolve) }.to raise_error(R10K::Git::GitError, /could not resolve/i)
    end
  end
end
