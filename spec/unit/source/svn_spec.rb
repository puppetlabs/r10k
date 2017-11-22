require 'spec_helper'
require 'r10k/source'

describe R10K::Source::SVN do

  subject do
    described_class.new('mysource', '/some/nonexistent/dir',
                        {:remote => 'https://svn-server.site/repo'})
  end

  it "stores the name" do
    expect(subject.name).to eq 'mysource'
  end

  it "stores the basedir" do
    expect(subject.basedir).to eq '/some/nonexistent/dir'
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
      expect(environments[0].dirname).to eq 'production'
      expect(environments[1].dirname).to eq 'apache'
      expect(environments[2].dirname).to eq 'dns'
      expect(environments[3].dirname).to eq 'robobutler'
    end
  end

  describe "generating environments with branch filter exclude prefix" do
    before do
      allow(subject.svn_remote).to receive(:branches).and_return ['master', 'development', 'dev-test', 'dev', 'test_2']
      subject.instance_variable_set(:@ignore_branch_prefixes, ['dev', 'test'])
    end

    let(:environments) { subject.generate_environments }

    it "creates an environment for each branch not in ignore_branch_prefixes" do
      expect(subject.generate_environments.size).to eq(2)
    end

    it "uses the branch name as the directory by default" do
      expect(environments[0].name).to eq 'production'
      expect(environments[1].name).to eq 'master'
    end
  end

  describe "filtering branches with ignore prefixes" do
    let(:branches) { ['master', 'development', 'production', 'dev-test', 'dev', 'test_2'] }
    let(:ignore_prefixes) { ['dev', 'test'] }

    it "filters branches" do
      expect(subject.filter_branches(branches, ignore_prefixes)).to eq(['master', 'production'])
    end
  end
end

describe R10K::Source::SVN, 'when prefixing is enabled' do
  subject do
    described_class.new(
      'mysource',
      '/some/nonexistent/dir',
      {
        :remote => 'https://svn-server.site/repo',
        :prefix => true
      }
    )
  end

  describe "generating prefixed environments" do
    before do
      allow(subject.svn_remote).to receive(:branches).and_return %w[apache dns robobutler]
    end

    let(:environments) { subject.generate_environments }

    it "creates an environment for each branch and the trunk" do
      expect(environments.size).to eq(4)
    end

    it "prefixes the source name to environments" do
      expect(environments[0].dirname).to eq 'mysource_production'
      expect(environments[1].dirname).to eq 'mysource_apache'
      expect(environments[2].dirname).to eq 'mysource_dns'
      expect(environments[3].dirname).to eq 'mysource_robobutler'
    end
  end
end

describe R10K::Source::SVN, 'when prefixing is disabled' do
  subject do
    described_class.new(
    'mysource',
    '/some/nonexistent/dir',
    {
      :remote => 'https://svn-server.site/repo',
      :prefix => false
    }
    )
  end

  describe "generating environments" do
    before do
      allow(subject.svn_remote).to receive(:branches).and_return %w[apache dns robobutler]
    end

    let(:environments) { subject.generate_environments }

    it "creates an environment for each branch and the trunk" do
      expect(environments.size).to eq(4)
    end

    it "does not prefix environments" do
      expect(environments[0].dirname).to eq 'production'
      expect(environments[1].dirname).to eq 'apache'
      expect(environments[2].dirname).to eq 'dns'
      expect(environments[3].dirname).to eq 'robobutler'
    end
  end
end


describe R10K::Source::SVN, 'when prefixing is overridden' do
  subject do
    described_class.new(
    'mysource',
    '/some/nonexistent/dir',
    {
      :remote => 'https://svn-server.site/repo',
      :prefix => "tenant1"
    }
    )
  end

  describe "generating prefixed environments" do
    before do
      allow(subject.svn_remote).to receive(:branches).and_return %w[apache dns robobutler]
    end

    let(:environments) { subject.generate_environments }

    it "creates an environment for each branch and the trunk" do
      expect(environments.size).to eq(4)
    end

    it "prefixes the prefix name to environments" do
      expect(environments[0].dirname).to eq 'tenant1_production'
      expect(environments[1].dirname).to eq 'tenant1_apache'
      expect(environments[2].dirname).to eq 'tenant1_dns'
      expect(environments[3].dirname).to eq 'tenant1_robobutler'
    end
  end
end


describe R10K::Source::SVN, 'registering as a source' do
  it "registers with the :svn key" do
    expect(R10K::Source.retrieve(:svn)).to eq described_class
  end
end
