require 'spec_helper'
require 'r10k/action/puppetfile/install'

describe R10K::Action::Puppetfile::Install do

  subject { described_class.new({root: "/some/nonexistent/path"}, []) }

  let(:puppetfile) { R10K::Puppetfile.new('/some/nonexistent/path', nil, nil) }


  before do
    allow(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, nil).and_return(puppetfile)
  end

  it_behaves_like "a puppetfile action"

  describe "installing modules" do
    let(:modules) do
      Array.new(4, R10K::Module::Base.new('author/modname', "/some/nonexistent/path/modname", nil))
    end

    before do
      allow(puppetfile).to receive(:purge!)
      allow(puppetfile).to receive(:modules).and_return(modules)
    end

    it "syncs each module in the Puppetfile" do
      expect(puppetfile).to receive(:load!)
      modules.each { |m| expect(m).to receive(:sync) }
      expect(subject.call).to eq true
    end

    it "returns false if a module failed to install" do
      expect(puppetfile).to receive(:load!)

      modules[0..2].each { |m| expect(m).to receive(:sync) }
      expect(modules[3]).to receive(:sync).and_raise
      expect(subject.call).to eq false
    end
  end

  describe "purging" do
    before do
      allow(puppetfile).to receive(:load!)
      allow(puppetfile).to receive(:modules).and_return([])
    end

    it "purges the moduledir after installation" do
      expect(puppetfile).to receive(:purge!)
      subject.call
    end
  end
end
