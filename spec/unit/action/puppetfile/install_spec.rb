require 'spec_helper'
require 'r10k/action/puppetfile/install'

describe R10K::Action::Puppetfile::Install do
  let(:default_opts) { {root: "/some/nonexistent/path"} }
  let(:puppetfile) { R10K::Puppetfile.new('/some/nonexistent/path', nil, nil) }

  def installer(opts = {}, argv = [], settings = {})
    opts = default_opts.merge(opts)
    return described_class.new(opts, argv, settings)
  end

  before(:each) do
    allow(puppetfile).to receive(:load!).and_return(nil)
    allow(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, nil, nil, nil).and_return(puppetfile)
  end

  it_behaves_like "a puppetfile install action"

  describe "installing modules" do
    let(:modules) do
      (1..4).map do |idx|
        R10K::Module::Base.new("author/modname#{idx}", "/some/nonexistent/path/modname#{idx}", nil)
      end
    end

    before do
      allow(puppetfile).to receive(:purge!)
      allow(puppetfile).to receive(:modules).and_return(modules)
      allow(puppetfile).to receive(:modules_by_vcs_cachedir).and_return({none: modules})
    end

    it "syncs each module in the Puppetfile" do
      modules.each { |m| expect(m).to receive(:sync) }

      expect(installer.call).to eq true
    end

    it "returns false if a module failed to install" do
      modules[0..2].each { |m| expect(m).to receive(:sync) }
      expect(modules[3]).to receive(:sync).and_raise

      expect(installer.call).to eq false
    end
  end

  describe "purging" do
    before do
      allow(puppetfile).to receive(:modules).and_return([])
    end

    it "purges the moduledir after installation" do
      expect(puppetfile).to receive(:purge!)

      installer.call
    end
  end

  describe "using custom paths" do
    it "can use a custom puppetfile path" do
      expect(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, "/some/other/path/Puppetfile", nil, nil).and_return(puppetfile)

      installer({puppetfile: "/some/other/path/Puppetfile"}).call
    end

    it "can use a custom moduledir path" do
      expect(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", "/some/other/path/site-modules", nil, nil, nil).and_return(puppetfile)

      installer({moduledir: "/some/other/path/site-modules"}).call
    end
  end

  describe "forcing to overwrite local changes" do
    before do
      allow(puppetfile).to receive(:modules).and_return([])
    end

    it "can use the force overwrite option" do
      subject = described_class.new({root: "/some/nonexistent/path", force: true}, [], {})
      expect(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, nil, nil, true).and_return(puppetfile)
      subject.call
    end

  end
end
