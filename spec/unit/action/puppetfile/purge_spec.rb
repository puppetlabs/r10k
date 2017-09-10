require 'spec_helper'
require 'r10k/action/puppetfile/purge'

describe R10K::Action::Puppetfile::Purge do
  let(:default_opts) { {root: "/some/nonexistent/path"} }
  let(:puppetfile) { instance_double('R10K::Puppetfile', :desired_contents => nil) }

  def purger(opts = {}, argv = [], settings = {})
    opts = default_opts.merge(opts)
    return described_class.new(opts, argv, settings)
  end

  before(:each) do
    allow(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, nil).and_return(puppetfile)
  end

  it_behaves_like "a puppetfile action"

  it "purges unmanaged entries in the Puppetfile moduledir" do
    expect(puppetfile).to receive(:purge!)

    purger.call
  end

  describe "using custom paths" do
    before(:each) do
      allow(puppetfile).to receive(:purge!)
    end

    it "can use a custom puppetfile path" do
      expect(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", nil, "/some/other/path/Puppetfile").and_return(puppetfile)

      purger({puppetfile: "/some/other/path/Puppetfile"}).call
    end

    it "can use a custom moduledir path" do
      expect(R10K::Puppetfile).to receive(:new).with("/some/nonexistent/path", "/some/other/path/site-modules", nil).and_return(puppetfile)

      purger({moduledir: "/some/other/path/site-modules"}).call
    end
  end
end
