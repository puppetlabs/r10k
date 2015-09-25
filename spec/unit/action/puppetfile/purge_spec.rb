require 'spec_helper'
require 'r10k/action/puppetfile/purge'

describe R10K::Action::Puppetfile::Purge do

  subject { described_class.new({root: "/some/nonexistent/path"}, []) }

  let(:puppetfile) { instance_double('R10K::Puppetfile') }

  before { allow(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, nil).and_return(puppetfile) }

  it_behaves_like "a puppetfile action"

  it "purges unmanaged entries in the Puppetfile moduledir" do
    allow(puppetfile).to receive(:load!)
    expect(puppetfile).to receive(:purge!)
    subject.call
  end
end
