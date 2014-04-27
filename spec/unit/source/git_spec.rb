require 'spec_helper'
require 'r10k/source'

describe R10K::Source::Git do

  subject do
    described_class.new('/some/nonexistent/dir', 'mysource',
                        {:remote => 'https://git-server/repo.git'})
  end

  describe "fetching branches" do
    it "fetches the git cache and loads the git environments" do
      expect(subject.cache).to receive(:sync)
      expect(subject).to receive(:load)
      subject.fetch
    end
  end

  describe "generating environments" do
    describe "when the cache has not been created" do
      before { allow(subject.cache).to receive(:cached?).and_return false }

      it "has an empty list of environments" do
        subject.load
        expect(subject.environments).to be_empty
      end
    end

    describe "when the cache has been created" do
      before do
        allow(subject.cache).to receive(:cached?).and_return true
        allow(subject.cache).to receive(:branches).and_return %w[master]
        subject.load
      end

      let(:master_env) { subject.environments.first }

      it "creates an environment for each branch" do
        expect(subject.environments).to have(1).items
      end

      it "copies the source remote to the environment" do
        expect(master_env.remote).to eq subject.remote
      end

      it "uses the branch name as the directory by default" do
        expect(master_env.dirname).to eq 'master'
      end
    end
  end
end

# Since prefixing is an immutable property of a source, it's easier to create
# a new context and duplicate stubs in a single location rather than packing a
# single test with all the stubs that entirely recreate the source.
describe R10K::Source::Git, 'when prefixing is enabled' do
  subject do
    described_class.new(
      '/some/nonexistent/dir',
      'prefixed',
      {
        :prefix => true,
        :remote => 'https://git-server/repo.git',
      })
  end

  describe "generating prefixed environments" do
    before do
      allow(subject.cache).to receive(:cached?).and_return true
      allow(subject.cache).to receive(:branches).and_return %w[master other]
      subject.load
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
