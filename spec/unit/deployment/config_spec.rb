require 'spec_helper'

describe R10K::Deployment::Config do

  describe "reading settings" do
    # Try all permutations of string/symbol values as arguments to #setting and
    # values in the config file
    x = [:key, "key"]
    matrix = x.product(x)

    matrix.each do |(searchvalue, configvalue)|
      it "treats #{searchvalue.inspect}:#{searchvalue.class} and #{configvalue.inspect}:#{configvalue.class} as equivalent" do
        expect(YAML).to receive(:load_file).with('foo/bar').and_return(configvalue => 'some/cache')
        subject = described_class.new('foo/bar')
        expect(subject.setting(searchvalue)).to eq 'some/cache'
      end
    end
  end

  describe "applying global settings" do
    describe "for the cachedir" do
      it "sets the git cache root when given" do
        expect(YAML).to receive(:load_file).with('foo/bar').and_return('cachedir' => 'some/cache')
        expect(R10K::Git::Cache.settings).to receive(:[]=).with(:cache_root, 'some/cache')
        described_class.new('foo/bar')
      end
    end

    describe "for the forge" do
      it "sets the proxy when given" do
        expect(YAML).to receive(:load_file).with('foo/bar').and_return('forge' => {'proxy' => 'https://proxy.url'})
        expect(R10K::Forge::ModuleRelease.settings).to receive(:[]=).with(:proxy, 'https://proxy.url')
        described_class.new('foo/bar')
      end
    end

    describe "for git" do
      it "sets the git provider when given" do
        expect(YAML).to receive(:load_file).with('foo/bar').and_return('git' => {'provider' => 'rugged'})
        expect(R10K::Git).to receive(:provider=).with(:rugged)
        described_class.new('foo/bar')
      end

      it "sets the git ssh username when given" do
        expect(YAML).to receive(:load_file).with('foo/bar').and_return('git' => {'username' => 'grit'})
        expect(R10K::Git.settings).to receive(:[]=).with(:username, 'grit')
        described_class.new('foo/bar')
      end

      it "sets the git private key when given" do
        expect(YAML).to receive(:load_file).with('foo/bar').and_return('git' => {'private_key' => '/home/user/.ssh/id_rsa'})
        expect(R10K::Git.settings).to receive(:[]=).with(:private_key, '/home/user/.ssh/id_rsa')
        described_class.new('foo/bar')
      end
    end
  end
end
