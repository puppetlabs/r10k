require 'spec_helper'
require 'r10k/git/cache'

describe R10K::Git::Cache do

  describe 'the default cache_root' do
    it 'is in the right location in linux', unless: R10K::Util::Platform.windows?  do
      expect(described_class.defaults[:cache_root]).to match(/\.r10k\/git/)
    end

    it 'is in the right location for windows', if: R10K::Util::Platform.windows? do
      expect(described_class.defaults[:cache_root]).to match(/[^.]r10k\/git/)
    end
  end

  let(:subclass) do
    Class.new(described_class) do
      def self.bare_repository
        Class.new { def initialize(*args) end }
      end
    end
  end

  subject { subclass.new('git://some/git/remote') }

  describe "updating the cache" do
    it "only updates the cache once" do
      expect(subject).to receive(:sync!).exactly(1).times
      subject.sync
      subject.sync
    end
  end

  describe "methods on the repository" do
    def expect_delegation(method)
      expect(subject.repo).to receive(method)
      subject.send(method)
    end

    it "delegates #git_dir" do
      expect_delegation(:git_dir)
    end

    it "delegates #objects_dir" do
      expect_delegation(:objects_dir)
    end

    it "delegates #branches" do
      expect_delegation(:branches)
    end

    it "delegates #tags" do
      expect_delegation(:tags)
    end

    it "delegates #exist?" do
      expect_delegation(:exist?)
    end

    it "aliases #cached? to #exist?" do
      expect(subject.repo).to receive(:exist?)
      subject.cached?
    end
  end

  describe "dirname sanitization" do
    it 'sanitizes cache directory name' do
      expect(subject.sanitized_dirname).to eq('git---some-git-remote')
    end

    context 'with username and password' do
      subject { subclass.new('https://"user:pa$$w0rd:@some/git/remote') }

      it 'sanitizes cache directory name' do
        expect(subject.sanitized_dirname).to eq('https---some-git-remote')
      end
    end
  end
end
