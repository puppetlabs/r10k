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
    before do
      allow(subject.svn_remote).to receive(:branches).and_return %w[apache dns robobutler]
    end

    let(:environments) { subject.generate_environments }

    it "creates an environment for each branch and the trunk" do
      expect(environments[0].name).to eq 'production'
      expect(environments[1].name).to eq 'apache'
      expect(environments[2].name).to eq 'dns'
      expect(environments[3].name).to eq 'robobutler'
    end

    it "maps trunk to production" do
      expect(environments[0].remote).to eq 'https://svn-server.site/repo/trunk'
    end

    it "sets the remote for branch environments to subdirectories of the branches/ directory" do
      expect(environments[1].remote).to eq 'https://svn-server.site/repo/branches/apache'
      expect(environments[2].remote).to eq 'https://svn-server.site/repo/branches/dns'
      expect(environments[3].remote).to eq 'https://svn-server.site/repo/branches/robobutler'
    end

    it "uses the branch name as the directory by default" do
      expect(environments[0].name).to eq 'production'
      expect(environments[1].name).to eq 'apache'
      expect(environments[2].name).to eq 'dns'
      expect(environments[3].name).to eq 'robobutler'
    end
  end
end

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
