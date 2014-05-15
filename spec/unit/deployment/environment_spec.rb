require 'spec_helper'
require 'r10k/deployment/environment'

describe R10K::Deployment::Environment do

  it "creates R10K::Environment::Git instances" do
    subject = described_class.new('gitref', 'git://git-server.local/git-remote.git', '/some/nonexistent/dir')
    expect(subject).to be_a_kind_of R10K::Environment::Git
  end

  it "uses the ref as the dirname by default" do
    subject = described_class.new('gitref', 'git://git-server.local/git-remote.git', '/some/nonexistent/dir')
    expect(subject.dirname).to eq 'gitref'
  end

  it "can specify an explicit dirname" do
    subject = described_class.new('gitref', 'git://git-server.local/git-remote.git', '/some/nonexistent/dir', 'explicit-dirname')
    expect(subject.dirname).to eq 'explicit-dirname'
  end

  it "supports prefixing for backwards compatibility" do
    subject = described_class.new('gitref', 'git://git-server.local/git-remote.git', '/some/nonexistent/dir', nil, 'source')
    expect(subject.dirname).to eq 'source_gitref'
  end
end
