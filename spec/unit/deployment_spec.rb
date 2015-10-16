require 'spec_helper'
require 'r10k/deployment'
require 'tmpdir'

describe R10K::Deployment do

  let(:confdir) { Dir.mktmpdir }

  let(:config) do
    R10K::Deployment::MockConfig.new(
      :sources => {
        :control => {
          :type => :mock,
          :basedir => File.join(confdir, 'environments'),
          :environments => %w[first second third],
        },
        :hiera => {
          :type => :mock,
          :basedir => File.join(confdir, 'hiera'),
          :environments => %w[fourth fifth sixth],
        }
      }
    )
  end

  subject(:deployment) { described_class.new(config) }

  let(:control) { deployment.sources.find { |source| source.name == :control } }
  let(:hiera)   { deployment.sources.find { |source| source.name == :hiera } }

  describe "loading" do
    describe "sources" do
      it "creates a source for each key in the ':sources' config entry" do
        expect(control.basedir).to eq(File.join(confdir, 'environments'))
        expect(hiera.basedir).to eq(File.join(confdir, 'hiera'))
      end
    end

    describe "loading environments" do
      it "loads environments from each source" do
        %w[first second third fourth fifth sixth].each do |env|
          expect(deployment.environments.map(&:name)).to include(env)
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
      expect(deployment.paths).to include(File.join(confdir, 'environments'))
      expect(deployment.paths).to include(File.join(confdir, 'hiera'))
    end
  end

  describe "paths and sources" do
    it "retrieves the path for each source" do
      p_a_s = deployment.paths_and_sources

      expect(p_a_s[File.join(confdir, 'environments')]).to eq([control])
      expect(p_a_s[File.join(confdir, 'hiera')]).to eq([hiera])
    end
  end

  describe "purging" do
    it "purges each managed directory" do
      env_basedir = double("basedir environments")
      hiera_basedir = double("basedir hiera")

      expect(env_basedir).to receive(:purge!)
      expect(hiera_basedir).to receive(:purge!)

      expect(R10K::Util::Basedir).to receive(:new).with(File.join(confdir, 'environments'), [control]).and_return(env_basedir)
      expect(R10K::Util::Basedir).to receive(:new).with(File.join(confdir, 'hiera'), [hiera]).and_return(hiera_basedir)

      deployment.purge!
    end
  end

  describe "accepting a visitor" do
    it "passes itself to the visitor" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit).with(:deployment, subject)
      subject.accept(visitor)
    end

    it "passes the visitor to each environment if the visitor yields" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit) do |type, other, &block|
        expect(type).to eq :deployment
        expect(other).to eq subject
        block.call
      end

      source1 = spy('source')
      expect(source1).to receive(:accept).with(visitor)
      source2 = spy('source')
      expect(source2).to receive(:accept).with(visitor)

      expect(subject).to receive(:sources).and_return([source1, source2])
      subject.accept(visitor)
    end
  end
end

describe R10K::Deployment, "with environment collisions" do

  let(:confdir) { Dir.mktmpdir }

  let(:config) do
    R10K::Deployment::MockConfig.new(
      :sources => {
        :s1 => {
          :type => :mock,
          :basedir => File.join(confdir, 'environments'),
          :environments => %w[first second third],
        },
        :s2 => {
          :type => :mock,
          :basedir => File.join(confdir, 'environments'),
          :environments => %w[third fourth fifth],
        }
      }
    )
  end

  subject(:deployment) { described_class.new(config) }

  it "raises an error when validating" do
    expect {
      deployment.validate!
    }.to raise_error(R10K::Error, /Environment collision at .* between s\d:third and s\d:third/)
  end
end

describe R10K::Deployment, "checking the 'sources' key" do

  {
    "when missing" => {},
    "when empty" => {:sources => []},
  }.each_pair do |desc, config_hash|
    describe desc do

      let(:config) { R10K::Deployment::MockConfig.new(config_hash) }
      subject(:deployment) { described_class.new(config) }

      it "raises an error when enumerating sources" do
        expect {
          deployment.sources
        }.to raise_error(R10K::Error, "Unable to load sources; the supplied configuration does not define the 'sources' key")
      end
    end
  end
end
