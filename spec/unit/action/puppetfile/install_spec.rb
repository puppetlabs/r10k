require 'spec_helper'
require 'r10k/action/puppetfile/install'

describe R10K::Action::Puppetfile::Install do
  let(:default_opts) { { root: "/some/nonexistent/path" } }
  let(:loader) {
    R10K::ModuleLoader::Puppetfile.new(
      basedir: '/some/nonexistent/path',
      overrides: {force: false})
  }

  def installer(opts = {}, argv = [], settings = {})
    opts = default_opts.merge(opts)
    return described_class.new(opts, argv, settings)
  end

  before(:each) do
    allow(loader).to receive(:load!).and_return({})
    allow(R10K::ModuleLoader::Puppetfile).to receive(:new).
      with({basedir: "/some/nonexistent/path",
            overrides: {force: false, modules: {default_ref: nil}}}).
      and_return(loader)
  end

  it_behaves_like "a puppetfile install action"

  describe "installing modules" do
    let(:modules) do
      (1..4).map do |idx|
        R10K::Module::Base.new("author/modname#{idx}",
                               "/some/nonexistent/path/modname#{idx}",
                               {})
      end
    end

    before do
      allow(loader).to receive(:load!).and_return({
        modules: modules,
        managed_directories: [],
        desired_contents: [],
        purge_exclusions: []
      })
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

    it "reads in the default for git refs" do
      modules.each { |m| expect(m).to receive(:sync) }
      expect(R10K::ModuleLoader::Puppetfile).to receive(:new).
        with({basedir: "/some/nonexistent/path",
              overrides: {force: false, modules: {default_ref: 'main'}}}).
        and_return(loader)

      installer({}, [], {git: {default_ref: 'main'}}).call
    end
  end

  describe "purging" do
    it "purges the moduledir after installation" do
      allow(loader).to receive(:load!).and_return({
        modules:             [],
        desired_contents:    [ 'root/foo' ],
        managed_directories: [ 'root' ],
        purge_exclusions:    [ 'root/**/**.rb' ]
      })

      mock_cleaner = double("cleaner")

      expect(R10K::Util::Cleaner).to receive(:new).
        with(["root"], ["root/foo"], ["root/**/**.rb"]).
        and_return(mock_cleaner)
      expect(mock_cleaner).to receive(:purge!)

      installer.call
    end
  end

  describe "using custom paths" do
    it "can use a custom moduledir path" do
      expect(R10K::ModuleLoader::Puppetfile).to receive(:new).
        with({basedir: "/some/nonexistent/path",
              overrides: {force: false, modules: {default_ref: nil}},
              puppetfile: "/some/other/path/Puppetfile"}).
        and_return(loader)

      installer({puppetfile: "/some/other/path/Puppetfile"}).call

      expect(R10K::ModuleLoader::Puppetfile).to receive(:new).
        with({basedir: "/some/nonexistent/path",
              overrides: {force: false, modules: {default_ref: nil}},
              moduledir: "/some/other/path/site-modules"}).
        and_return(loader)

      installer({moduledir: "/some/other/path/site-modules"}).call
    end
  end

  describe "forcing to overwrite local changes" do
    it "can use the force overwrite option" do
      allow(loader).to receive(:load!).and_return({ modules: [] })

      subject = described_class.new({root: "/some/nonexistent/path", force: true}, [], {})
      expect(R10K::ModuleLoader::Puppetfile).to receive(:new).
        with({basedir: "/some/nonexistent/path",
              overrides: {force: true, modules: {default_ref: nil}}}).
        and_return(loader)
      subject.call
    end

  end
end
