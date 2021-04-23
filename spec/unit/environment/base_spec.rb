require 'spec_helper'
require 'r10k/environment'

describe R10K::Environment::Base do

  subject(:environment) { described_class.new('envname', '/some/imaginary/path', 'env_name', {}) }

  it "can return the fully qualified path" do
    expect(environment.path).to eq(Pathname.new('/some/imaginary/path/env_name'))
  end

  it "raises an exception when #sync is called" do
    expect { environment.sync }.to raise_error(NotImplementedError)
  end

  describe "accepting a visitor" do
    it "passes itself to the visitor" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit).with(:environment, subject)
      subject.accept(visitor)
    end

    it "passes the visitor to the puppetfile if the visitor yields" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit) do |type, other, &block|
        expect(type).to eq :environment
        expect(other).to eq subject
        block.call
      end

      pf = spy('puppetfile')
      expect(pf).to receive(:accept).with(visitor)

      expect(subject).to receive(:puppetfile).and_return(pf)
      subject.accept(visitor)
    end
  end

  describe "#whitelist" do
    let(:whitelist) do
      ['**/*.xpp', 'custom', '*.tmp']
    end

    it "combines given patterns with full_path to env" do
      expect(subject.whitelist(whitelist)).to all(start_with(subject.path.to_s))
    end
  end

  describe "#purge_exclusions" do
    let(:mock_env) { instance_double("R10K::Environment::Base") }
    let(:mock_puppetfile) { instance_double("R10K::Puppetfile", :environment= => true, :environment => mock_env) }

    before(:each) do
      allow(mock_puppetfile).to receive(:managed_directories).and_return([])
      allow(mock_puppetfile).to receive(:desired_contents).and_return([])
      allow(mock_puppetfile).to receive(:previous_version=)
      allow(R10K::Puppetfile).to receive(:new).and_return(mock_puppetfile)
    end

    it "excludes .r10k-deploy.json" do
      expect(subject.purge_exclusions).to include(/r10k-deploy\.json/)
    end

    it "excludes puppetfile managed directories" do
      managed_dirs = [
        '/some/imaginary/path/env_name/modules',
        '/some/imaginary/path/env_name/data',
      ]

      expect(mock_puppetfile).to receive(:managed_directories).and_return(managed_dirs)

      exclusions = subject.purge_exclusions

      managed_dirs.each do |dir|
        expect(exclusions).to include(dir)
      end
    end

    describe "puppetfile desired contents" do
      let(:desired_contents) do
        basedir = subject.path.to_s

        [ 'modules/apache', 'data/local/site' ].collect do |c|
          File.join(basedir, c)
        end
      end

      before(:each) do
        allow(File).to receive(:directory?).with(/^\/some\/imaginary\/path/).and_return(true)

        expect(mock_puppetfile).to receive(:desired_contents).and_return(desired_contents)
      end

      it "excludes desired directory contents with glob" do
        exclusions = subject.purge_exclusions

        expect(exclusions).to include(/#{Regexp.escape(File.join('apache', '**', '*'))}$/)
        expect(exclusions).to include(/#{Regexp.escape(File.join('site', '**', '*'))}$/)
      end

      it "excludes ancestors of desired directories" do
        exclusions = subject.purge_exclusions

        expect(exclusions).to include(/modules$/)
        expect(exclusions).to include(/data\/local$/)
        expect(exclusions).to include(/data$/)
      end
    end
  end
end
