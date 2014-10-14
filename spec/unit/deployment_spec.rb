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

  let(:control) { deployment.sources.find { |source| source.name == :control } }
  let(:hiera)   { deployment.sources.find { |source| source.name == :hiera } }

  describe "loading" do
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

  describe "paths" do
    it "retrieves the path for each source" do
      expect(deployment.paths).to include(File.join(config.confdir, 'environments'))
      expect(deployment.paths).to include(File.join(config.confdir, 'hiera'))
    end
  end

  describe "paths and sources" do
    it "retrieves the path for each source" do
      p_a_s = deployment.paths_and_sources

      expect(p_a_s[File.join(config.confdir, 'environments')]).to eq([control])
      expect(p_a_s[File.join(config.confdir, 'hiera')]).to eq([hiera])
    end
  end

  describe "purging" do
    it "purges each managed directory" do
      env_basedir = double("basedir environments")
      hiera_basedir = double("basedir hiera")

      expect(env_basedir).to receive(:purge!)
      expect(hiera_basedir).to receive(:purge!)

      expect(R10K::Util::Basedir).to receive(:new).with(File.join(config.confdir, 'environments'), [control]).and_return(env_basedir)
      expect(R10K::Util::Basedir).to receive(:new).with(File.join(config.confdir, 'hiera'), [hiera]).and_return(hiera_basedir)

      deployment.purge!
    end
  end
end
