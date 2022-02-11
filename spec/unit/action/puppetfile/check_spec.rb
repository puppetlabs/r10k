require 'spec_helper'
require 'r10k/action/puppetfile/check'

describe R10K::Action::Puppetfile::Check do
  let(:default_opts) { {root: "/some/nonexistent/path"} }
  let(:modules) do
    [R10K::Module::Git.new("author/modname",
                           "/some/nonexistent/path/modname",
                           {git: 'https://my/git/remote', branch: 'main'})]
  end


  let(:loader) { instance_double('R10K::ModuleLoader::Puppetfile', :load! => {}, :modules => modules) }

  def checker(opts = {}, argv = [], settings = {})
    opts = default_opts.merge(opts)
    return described_class.new(opts, argv, settings)
  end

  before(:each) do
    allow(R10K::ModuleLoader::Puppetfile).
      to receive(:new).
      with({
        basedir: "/some/nonexistent/path",
        overrides: {modules: {default_ref: nil}}
      }).and_return(loader)
  end

  it_behaves_like "a puppetfile action"

  describe 'when no ref is defined' do
    let(:modules) do
      [R10K::Module::Git.new("author/modname",
                             "/some/nonexistent/path/modname",
                             {git: 'https://my/git/remote'})]
    end

    it 'returns an error message' do
      expect($stderr).to receive(:puts).with(/no ref defined/i)
      checker.call
    end
  end

  describe 'when a default_ref is defined' do
    let(:modules) do
      [R10K::Module::Git.new("author/modname",
                             "/some/nonexistent/path/modname",
                             {git: 'https://my/git/remote',
                              overrides: {modules: {default_ref: 'main'}}})]
    end

    it 'is valid syntax' do
      expect($stderr).to receive(:puts).with(/Syntax OK/i)
      checker.call
    end
  end

  it "prints 'Syntax OK' when the Puppetfile syntax could be validated" do
    expect($stderr).to receive(:puts).with("Syntax OK")

    checker.call
  end

  it "prints an error message when validating the Puppetfile syntax raised an error" do
    allow(loader).to receive(:load!).and_raise(R10K::Error.new("Boom!"))
    allow(R10K::Errors::Formatting).
      to receive(:format_exception).
      with(instance_of(R10K::Error), anything).
      and_return("Formatted error message")

    expect($stderr).to receive(:puts).with("Formatted error message")

    checker.call
  end

  it "respects --puppetfile option" do
    allow($stderr).to receive(:puts)

    expect(R10K::ModuleLoader::Puppetfile).
      to receive(:new).
      with({
        basedir: "/some/nonexistent/path",
        overrides: {modules: {default_ref: nil}},
        puppetfile: "/custom/puppetfile/path"
      }).and_return(loader)

    checker({puppetfile: "/custom/puppetfile/path"}).call
  end
end
