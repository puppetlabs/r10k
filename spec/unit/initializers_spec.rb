require 'spec_helper'
require 'r10k/initializers'

describe R10K::Initializers::GitInitializer do
  it "configures the Git provider" do
    subject = described_class.new({:provider => :rugged})
    expect(R10K::Git).to receive(:provider=).with(:rugged)
    subject.call
  end

  it "configures the Git username" do
    subject = described_class.new({:username => 'git'})
    expect(R10K::Git.settings).to receive(:[]=).with(:username, 'git')
    subject.call
  end

  it "configures the Git private key" do
    subject = described_class.new({:private_key => '/etc/puppetlabs/r10k/id_rsa'})
    expect(R10K::Git.settings).to receive(:[]=).with(:private_key, '/etc/puppetlabs/r10k/id_rsa')
    subject.call
  end
end

describe R10K::Initializers::ForgeInitializer do
  it "configures the Forge proxy" do
    subject = described_class.new({:proxy => 'http://my.site.proxy:3128'})
    expect(R10K::Forge::ModuleRelease.settings).to receive(:[]=).with(:proxy, 'http://my.site.proxy:3128')
    subject.call
  end

  it "configures the Forge baseurl" do
    subject = described_class.new({:baseurl => 'https://my.site.forge'})
    expect(R10K::Forge::ModuleRelease.settings).to receive(:[]=).with(:baseurl, 'https://my.site.forge')
    subject.call
  end
end

describe R10K::Initializers::GlobalInitializer do
  it "logs a warning if purgedirs was set" do
    subject = described_class.new({:purgedirs => 'This setting has been deprecated for over two years :('})
    expect(subject.logger).to receive(:warn).with('the purgedirs key in r10k.yaml is deprecated. it is currently ignored.')
    subject.call
  end

  it "sets the Git cache_root" do
    subject = described_class.new({:cachedir => '/var/cache/r10k'})
    expect(R10K::Git::Cache.settings).to receive(:[]=).with(:cache_root, '/var/cache/r10k')
    subject.call
  end

  it "delegates git settings to the Git initializer" do
    git = instance_double('R10K::Initializers::GitInitializer')
    expect(git).to receive(:call)
    expect(R10K::Initializers::GitInitializer).to receive(:new).and_return(git)

    subject = described_class.new({:git => {}})
    subject.call
  end

  it "delegates forge settings to the Forge initializer" do
    forge = instance_double('R10K::Initializers::ForgeInitializer')
    expect(forge).to receive(:call)
    expect(R10K::Initializers::ForgeInitializer).to receive(:new).and_return(forge)

    subject = described_class.new({:forge => {}})
    subject.call
  end
end
