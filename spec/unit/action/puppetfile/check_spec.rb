require 'spec_helper'
require 'r10k/action/puppetfile/check'

describe R10K::Action::Puppetfile::Check do
  let(:default_opts) { {root: "/some/nonexistent/path"} }
  let(:puppetfile) { instance_double('R10K::Puppetfile', :load! => true) }

  def checker(opts = {}, argv = [], settings = {})
    opts = default_opts.merge(opts)
    return described_class.new(opts, argv, settings)
  end

  before(:each) do
    allow(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, nil).and_return(puppetfile)
  end

  it_behaves_like "a puppetfile action"

  it "prints 'Syntax OK' when the Puppetfile syntax could be validated" do
    expect($stderr).to receive(:puts).with("Syntax OK")

    checker.call
  end

  it "prints an error message when validating the Puppetfile syntax raised an error" do
    allow(puppetfile).to receive(:load!).and_raise(R10K::Error.new("Boom!"))
    allow(R10K::Errors::Formatting).to receive(:format_exception).with(instance_of(R10K::Error), anything).and_return("Formatted error message")

    expect($stderr).to receive(:puts).with("Formatted error message")

    checker.call
  end

  it "respects --puppetfile option" do
    allow($stderr).to receive(:puts)

    expect(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, "/custom/puppetfile/path").and_return(puppetfile)

    checker({puppetfile: "/custom/puppetfile/path"}).call
  end
end
