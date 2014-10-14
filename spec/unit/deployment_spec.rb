require 'spec_helper'
require 'r10k/deployment'
require 'tmpdir'

describe R10K::Deployment do

  let(:config) do
    Object.new.tap do |o|

      # Scope hack. Ignore.
      def o.confdir
        @confdir ||= Dir.mktmpdir
      end

      def o.setting(key)
        hash = {
          :sources => {
            :control => {
              :basedir => File.join(confdir, 'environments'),
              :remote  => 'git://some-git-server/puppet-control.git',
            },
            :hiera => {
              :basedir => File.join(confdir, 'hiera'),
              :remote  => 'git://some-git-server/hiera.git',
            }
          }
        }

        hash[key]
      end
    end
  end

  subject(:deployment) { described_class.new(config) }

  describe "loading" do
    let(:control) { deployment.sources.find { |source| source.name == :control } }
    let(:hiera)   { deployment.sources.find { |source| source.name == :hiera } }

    describe "sources" do
      it "creates a source for each key in the ':sources' config entry" do

        expect(control.basedir).to eq(File.join(config.confdir, 'environments'))
        expect(hiera.basedir).to eq(File.join(config.confdir, 'hiera'))
      end
    end

    describe "loading environments" do
      before do
        allow(control).to receive(:environments).and_return(%w[first second third])
        allow(hiera).to receive(:environments).and_return(%w[fourth fifth sixth])
      end

      it "loads environments from each source" do
        %w[first second third fourth fifth sixth].each do |env|
          expect(deployment.environments).to include(env)
        end
      end
    end
  end

  describe "preloading" do
    it "invokes #preload! on each source" do
      deployment.sources.each do |source|
        expect(source).to receive(:preload!)
      end
      deployment.preload!
    end
  end
end
