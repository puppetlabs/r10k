require 'spec_helper'
require 'r10k/source'

describe R10K::Source::Git do

  subject do
    described_class.new('mysource', '/some/nonexistent/dir',
                        {:remote => 'https://git-server/repo.git'})
  end

  it "stores the name" do
    expect(subject.name).to eq 'mysource'
  end

  it "stores the basedir" do
    expect(subject.basedir).to eq '/some/nonexistent/dir'
  end

  describe "preloading" do
    it "fetches the git cache" do
      expect(subject.cache).to receive(:sync)
      subject.preload!
    end
  end

  describe "lazily generating environments" do
    it "returns an empty list of environments when the cache has not been created" do
      allow(subject.cache).to receive(:cached?).and_return false
      expect(subject.environments).to be_empty
    end

    it "generates environments when the cache is present and environments have not been loaded" do
      allow(subject.cache).to receive(:cached?).and_return true
      allow(subject).to receive(:generate_environments).and_return %w[hi]
      expect(subject.environments).to have(1).items
    end

    it "doesn't recreate environments if they have already been loaded" do
      allow(subject.cache).to receive(:cached?).and_return true
      allow(subject).to receive(:generate_environments).once.and_return %w[hi]
      expect(subject.environments).to have(1).items
      expect(subject.environments).to have(1).items
    end
  end

  describe "eagerly generating environments" do
    before do
      allow(subject.cache).to receive(:branches).and_return %w[master]
    end

    let(:master_env) { subject.generate_environments.first }

    it "creates an environment for each branch" do
      expect(subject.generate_environments).to have(1).items
    end

    it "copies the source remote to the environment" do
      expect(master_env.remote).to eq subject.remote
    end

    it "uses the branch name as the directory by default" do
      expect(master_env.dirname).to eq 'master'
    end
  end
end

describe R10K::Source::Git, "handling invalid branch names" do
  %w[correct_and_warn correct].each do |setting|
    describe "when invalid is #{setting}" do
      subject do
        described_class.new('/some/nonexistent/dir', 'mysource', {
          :remote   => 'https://git-server/repo.git',
          :settings => { :invalid => setting }
        })
      end

      before do
        allow(subject.cache).to receive(:branches).and_return ['master', 'invalid-branch']
      end

      it "creates an environment for each branch" do
        expect(subject.generate_environments).to have(2).items
      end

      it "removes invalid characters from branch names" do
        invalid_env = subject.generate_environments.last
        expect(invalid_env.dirname).to eq 'invalid_branch'
      end
    end
  end

  describe "when invalid is 'error'" do
    subject do
      described_class.new('/some/nonexistent/dir', 'mysource', {
        :remote   => 'https://git-server/repo.git',
        :settings => { :invalid => 'error' }
      })
    end

    before do
      allow(subject.cache).to receive(:branches).and_return ['master', 'invalid-branch']
    end

    it "only creates an environment for valid branches" do
      expect(subject.generate_environments).to have(1).items
    end
  end
end

# Since prefixing is an immutable property of a source, it's easier to create
# a new context and duplicate stubs in a single location rather than packing a
# single test with all the stubs that entirely recreate the source.
describe R10K::Source::Git, 'when prefixing is enabled' do
  subject do
    described_class.new(
      'prefixed',
      '/some/nonexistent/dir',
      {
        :prefix => true,
        :remote => 'https://git-server/repo.git',
      })
  end

  describe "generating prefixed environments" do
    before do
      allow(subject.cache).to receive(:cached?).and_return true
      allow(subject.cache).to receive(:branches).and_return %w[master other]
    end

    let(:environments) { subject.environments }

    it "creates an environment for each branch" do
      expect(subject.environments).to have(2).items
    end

    it "prefixes the source name to environments when prefixing is enabled" do
      expect(environments[0].dirname).to eq 'prefixed_master'
      expect(environments[1].dirname).to eq 'prefixed_other'
    end
  end
end

describe R10K::Source::Git, 'registering as a source' do
  it "registers with the :git key" do
    expect(R10K::Source.retrieve(:git)).to eq described_class
  end

  it "registers with the nil key" do
    expect(R10K::Source.retrieve(nil)).to eq described_class
  end
end

describe R10K::Source::Git::BranchName do
  describe "prefixing" do
    it "uses the branch name as the dirname when prefixing is off" do
      bn = described_class.new('mybranch', {:prefix => false, :sourcename => 'foo'})
      expect(bn.dirname).to eq 'mybranch'
    end

    it "prepends the source name when prefixing is on" do
      bn = described_class.new('mybranch', {:prefix => true, :sourcename => 'foo'})
      expect(bn.dirname).to eq 'foo_mybranch'
    end
  end

  describe "determining the validate behavior with :invalid" do
    [
      ['correct_and_warn', {:validate => true, :correct => true}],
      ['correct',          {:validate => false, :correct => true}],
      ['error',            {:validate => true, :correct => false}],
    ].each do |(setting, outcome)|
      it "treats #{setting} as #{outcome.inspect}" do
        bn = described_class.new('mybranch', {:invalid => setting})
        expect(bn.validate?).to eq outcome[:validate]
        expect(bn.correct?).to eq outcome[:correct]
      end
    end
  end

  describe "determining if a branch is a valid environment name" do
    invalid_cases = [
      'hyphenated-branch',
      'dotted.branch',
      'slashed/branch',
      'at@branch',
      'http://branch'
    ]

    valid_cases = [
      'my_branchname',
      'my_issue_346',
    ]

    describe "and validate is false" do
      invalid_cases.each do |branch|
        it "is valid if the branch is #{branch}" do
          bn = described_class.new(branch, {:validate => false})
          expect(bn).to be_valid
        end
      end

      valid_cases.each do |branch|
        it "is valid if the branch is #{branch}" do
          bn = described_class.new(branch, {:validate => false})
          expect(bn).to be_valid
        end
      end
    end

    describe "and validate is true" do
      invalid_cases.each do |branch|
        it "is invalid if the branch is #{branch}" do
          bn = described_class.new(branch, {:validate => true})
          expect(bn).to_not be_valid
        end
      end

      valid_cases.each do |branch|
        it "is valid if the branch is #{branch}" do
          bn = described_class.new(branch, {:validate => true})
          expect(bn).to be_valid
        end
      end

    end
  end

  describe "correcting branch names" do
    invalid_cases = [
      'hyphenated-branch',
      'dotted.branch',
      'slashed/branch',
      'at@branch',
      'http://branch'
    ]

    valid_cases = [
      'my_branchname',
      'my_issue_346',
    ]

    describe "and correct is false" do
      invalid_cases.each do |branch|
        it "doesn't modify #{branch}" do
          bn = described_class.new(branch.dup, {:correct => false})
          expect(bn.dirname).to eq branch
        end
      end

      valid_cases.each do |branch|
        it "doesn't modify #{branch}" do
          bn = described_class.new(branch.dup, {:correct => false})
          expect(bn.dirname).to eq branch
        end
      end
    end

    describe "and correct is true" do
      invalid_cases.each do |branch|
        it "replaces invalid characters in #{branch} with underscores" do
          bn = described_class.new(branch.dup, {:correct => true})
          expect(bn.dirname).to eq branch.gsub(/\W/, '_')
        end
      end

      valid_cases.each do |branch|
        it "doesn't modify #{branch}" do
          bn = described_class.new(branch.dup, {:correct => true})
          expect(bn.dirname).to eq branch
        end
      end
    end
  end
end
