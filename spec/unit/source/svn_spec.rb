require 'spec_helper'
require 'r10k/source'

describe R10K::Source::SVN do

  subject do
    described_class.new('/some/nonexistent/dir', 'mysource',
                        {:remote => 'https://svn-server.site/repo'})
  end

  describe "lazily generating environments" do
    it "generates environments when they have not been loaded" do
      expect(subject).to receive(:generate_environments).and_return %w[hi]
      expect(subject.environments).to eq %w[hi]
    end

    it "doesn't recreate environments if they have already been loaded" do
      expect(subject).to receive(:generate_environments).once.and_return %w[hi]
      subject.environments
      subject.environments
    end
  end

  describe "eagerly generating environments" do
    it "creates an environment for each branch"
    it "copies the source remote and the sub-path to the environment"
    it "uses the branch name as the directory by default"
  end
end

# Since prefixing is an immutable property of a source, it's easier to create
# a new context and duplicate stubs in a single location rather than packing a
# single test with all the stubs that entirely recreate the source.
describe R10K::Source::SVN, 'when prefixing is enabled' do

  describe "generating prefixed environments" do
    it "creates an environment for each branch"
    it "prefixes the source name to environments when prefixing is enabled"
  end
end

describe R10K::Source::SVN, 'registering as a source' do
  it "registers with the :svn key" do
    expect(R10K::Source.retrieve(:svn)).to eq described_class
  end
end
