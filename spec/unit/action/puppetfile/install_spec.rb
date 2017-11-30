require 'spec_helper'
require 'r10k/action/puppetfile/install'

describe R10K::Action::Puppetfile::Install do

  subject { described_class.new({root: "/some/nonexistent/path"}, []) }

  let(:puppetfile) { R10K::Puppetfile.new('/some/nonexistent/path', nil, nil) }

  before(:each) do
    allow(puppetfile).to receive(:load!).and_return(nil)
    allow(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, nil, nil, nil).and_return(puppetfile)
  end

  it_behaves_like "a puppetfile install action"

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

  describe "using custom paths" do
    let(:puppetfile) { instance_double("R10K::Puppetfile", load!: nil, accept: nil, purge!: nil) }

    it "can use a custom puppetfile path" do
      subject = described_class.new({root: "/some/nonexistent/path", puppetfile: "/some/other/path/Puppetfile"}, [])
      expect(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, "/some/other/path/Puppetfile", nil, nil).and_return(puppetfile)
      subject.call
    end

    it "can use a custom moduledir path" do
      subject = described_class.new({root: "/some/nonexistent/path", moduledir: "/some/other/path/site-modules"}, [])
      expect(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", "/some/other/path/site-modules", nil, nil, nil).and_return(puppetfile)
      subject.call
    end
  end

  describe "forcing to overwrite local changes" do
    before do
      allow(puppetfile).to receive(:modules).and_return([])
    end

    it "can use the force overwrite option" do
      subject = described_class.new({root: "/some/nonexistent/path", force: true}, [])
      expect(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, nil, nil, true).and_return(puppetfile)
      subject.call
    end

  end
end
