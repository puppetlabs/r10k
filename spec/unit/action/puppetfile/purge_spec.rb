require 'spec_helper'
require 'r10k/action/puppetfile/purge'

describe R10K::Action::Puppetfile::Purge do
  let(:default_opts) { {root: "/some/nonexistent/path"} }
  let(:puppetfile) do
    instance_double('R10K::ModuleLoader::Puppetfile',
                    :load! => {
                      :modules             => %w{mod},
                      :managed_directories => %w{foo},
                      :desired_contents    => %w{bar},
                      :purge_exclusions    => %w{baz}
                    })
  end

  def purger(opts = {}, argv = [], settings = {})
    opts = default_opts.merge(opts)
    return described_class.new(opts, argv, settings)
  end

  before(:each) do
    allow(R10K::ModuleLoader::Puppetfile).to receive(:new).
      with({basedir: "/some/nonexistent/path"}).
      and_return(puppetfile)
  end

  it_behaves_like "a puppetfile action"

  it "purges unmanaged entries in the Puppetfile moduledir" do
    mock_cleaner = double("cleaner")

    expect(R10K::Util::Cleaner).to receive(:new).
      with(["foo"], ["bar"], ["baz"]).
      and_return(mock_cleaner)

    expect(mock_cleaner).to receive(:purge!)

    purger.call
  end

  describe "using custom paths" do
    it "can use a custom puppetfile path" do
      expect(R10K::ModuleLoader::Puppetfile).to receive(:new).
        with({basedir: "/some/nonexistent/path",
              puppetfile: "/some/other/path/Puppetfile"}).
        and_return(puppetfile)

      purger({puppetfile: "/some/other/path/Puppetfile"}).call
    end

    it "can use a custom moduledir path" do
      expect(R10K::ModuleLoader::Puppetfile).to receive(:new).
        with({basedir: "/some/nonexistent/path",
              moduledir: "/some/other/path/site-modules"}).
        and_return(puppetfile)

      purger({moduledir: "/some/other/path/site-modules"}).call
    end
  end
end
