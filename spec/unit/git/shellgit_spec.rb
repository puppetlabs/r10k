require 'spec_helper'
require 'r10k/git/shellgit'

RSpec.describe R10K::Git::ShellGit do
  describe ".reset" do
    it "returns true when git exits zero" do
      expect(subject).to receive(:git).with(array_including('reset'), any_args).and_return(double(:result, success?: true))

      expect(subject.reset('testref')).to eq(true)
    end

    it "raises R10K::Git::GitError with stderr when git exits non-zero" do
      expect(subject).to receive(:git).with(array_including('reset'), any_args).and_return(double(:result, success?: false, stderr: 'something failed'))

      expect { subject.reset('testref') }.to raise_error(R10K::Git::GitError, /something failed/)
    end

    it "adds --hard flag to cmd when opts[:hard]" do
      expect(subject).to receive(:git).with(array_including('reset', '--hard'), any_args).and_return(double(:result, success?: true))

      expect(subject.reset('testref', hard: true)).to eq(true)
    end
  end

  describe ".clean" do
    it "returns true when git exits zero" do
      expect(subject).to receive(:git).with(array_including('clean'), any_args).and_return(double(:result, success?: true))

      expect(subject.clean()).to eq(true)
    end

    it "raises R10K::Git::GitError with stderr when git exits non-zero" do
      expect(subject).to receive(:git).with(array_including('clean'), any_args).and_return(double(:result, success?: false, stderr: 'something failed'))

      expect { subject.clean() }.to raise_error(R10K::Git::GitError, /something failed/)
    end

    it "adds --force flag to cmd when opts[:force]" do
      expect(subject).to receive(:git).with(array_including('clean', '--force'), any_args).and_return(double(:result, success?: true))

      expect(subject.clean(force: true)).to eq(true)
    end

    it "adds --excludes options to cmd when opts[:excludes]" do
      excludes = [ 'exclude_pattern_1', 'second_exclude_pattern' ]

      expect(subject).to receive(:git).with(array_including(excludes.unshift('clean')), any_args).and_return(double(:result, success?: true))

      expect(subject.clean(excludes: excludes)).to eq(true)
    end
  end

  describe ".rev_parse" do
    it "returns stdout when git exits zero" do
      to_resolve = 'branch_name'

      expect(subject).to receive(:git).with(array_including('rev-parse', to_resolve), any_args).and_return(double(:result, success?: true, stdout: "123abc"))

      expect(subject.rev_parse(to_resolve)).to eq('123abc')
    end

    it "raises R10K::Git::GitError with stderr when git exits non-zero" do
      expect(subject).to receive(:git).with(array_including('rev-parse'), any_args).and_return(double(:result, success?: false, stderr: 'something failed'))

      expect { subject.rev_parse('something') }.to raise_error(R10K::Git::GitError, /something failed/)
    end
  end

  describe ".blob_at" do
    it "returns stdout when git exits zero" do
      branch = 'shire'
      path = 'TheRoadGoesEverOn'
      blob_data = "Eyes that fire and sword have seen\nAnd horror in the halls of stone\nLook at last on meadows green\nAnd trees and hills they long have known."

      expect(subject).to receive(:git).with(array_including('cat-file', '--textconv', "#{branch}:#{path}"), any_args).and_return(double(:result, success?: true, stdout: blob_data))

      expect(subject.blob_at(branch, path)).to eq(blob_data)
    end

    it "raises R10K::Git::GitError with stderr when git exits non-zero" do
      expect(subject).to receive(:git).with(array_including('cat-file'), any_args).and_return(double(:result, success?: false, stderr: 'something failed'))

      expect { subject.blob_at('branch', 'path') }.to raise_error(R10K::Git::GitError, /something failed/)
    end
  end

  describe ".branch_list" do
    it "returns an array of each branch from stdout when git exits zero" do
      mock_output = "refs/heads/191_cache_update_fns\nrefs/heads/195_serialize_envmap\nrefs/heads/457_api_fixups\n"
      expect(subject).to receive(:git).with(array_including('for-each-ref'), any_args).and_return(double(:result, success?: true, stdout: mock_output))

      expect(subject.branch_list).to contain_exactly('191_cache_update_fns', '195_serialize_envmap', '457_api_fixups')
    end

    it "raises R10K::Git::GitError with stderr when git exits non-zero" do
      expect(subject).to receive(:git).with(array_including('for-each-ref'), any_args).and_return(double(:result, success?: false, stderr: 'something failed'))

      expect { subject.branch_list }.to raise_error(R10K::Git::GitError, /something failed/)
    end
  end

  describe ".git" do
    let(:result_success) { double(:result, success?: true, stdout: 'successful') }
    let(:subprocess) { instance_double(R10K::Util::Subprocess) }

    before(:each) do
      allow(R10K::Util::Subprocess).to receive(:new).and_return(subprocess)
      allow(subprocess).to receive(:raise_on_fail=)
      allow(subprocess).to receive(:logger=)
      allow(subprocess).to receive(:execute).and_return(result_success)
    end

    it "defaults raise_on_fail to true" do
      expect(subprocess).to receive(:raise_on_fail=).with(true)

      cmd = ['ls-files']
      expect(subject.git(cmd)).to eq(result_success)
    end

    it "allows raise_on_fail to be set via opts" do
      expect(subprocess).to receive(:raise_on_fail=).with(false)

      cmd = ['ls-files']
      expect(subject.git(cmd, raise_on_fail: false)).to eq(result_success)
    end

    context "when opts[:path] is set" do
      let(:path) { '/tmp/checkout' }
      let(:opts) { { path: path } }

      it "sets --git-dir option correctly" do
        git_dir = File.join(path, '.git')
        expect(R10K::Util::Subprocess).to receive(:new).with(array_including('--git-dir', git_dir)).and_return(subprocess)

        cmd = ['ls-files']
        expect(subject.git(cmd, opts)).to eq(result_success)
      end

      it "sets --work-tree option correctly" do
        work_dir = path
        expect(R10K::Util::Subprocess).to receive(:new).with(array_including('--work-tree', path)).and_return(subprocess)

        cmd = ['ls-files']
        expect(subject.git(cmd, opts)).to eq(result_success)
      end
    end

    context "when opts[:path] is not set" do
      let(:git_dir) { '/tmp/cache/repo-cache.git/' }
      let(:work_tree) { '/tmp/checkouts/working' }

      it "honors opts[:git_dir] independently" do
        expect(R10K::Util::Subprocess).to receive(:new).with(array_including('--git-dir', git_dir)).and_return(subprocess)
        expect(R10K::Util::Subprocess).to_not receive(:new).with(array_including('--work-tree'))

        cmd = ['ls-files']
        opts = { git_dir: git_dir }
        expect(subject.git(cmd, opts)).to eq(result_success)
      end

      it "honors opts[:work_tree] independently" do
        expect(R10K::Util::Subprocess).to receive(:new).with(array_including('--work-tree', work_tree)).and_return(subprocess)
        expect(R10K::Util::Subprocess).to_not receive(:new).with(array_including('--git-dir'))

        cmd = ['ls-files']
        opts = { work_tree: work_tree }
        expect(subject.git(cmd, opts)).to eq(result_success)
      end
    end
  end
end
