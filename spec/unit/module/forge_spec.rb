require 'r10k/module/forge'
require 'semver'
require 'spec_helper'

describe R10K::Module::Forge do
  before :each do
    allow_any_instance_of(described_class).to receive(:execute).and_raise "Tests should never invoke system calls"

    log = double('stub logger').as_null_object
    allow_any_instance_of(described_class).to receive(:logger).and_return log
  end

  let(:fixture_modulepath) { File.expand_path('spec/fixtures/module/forge', PROJECT_ROOT) }
  let(:empty_modulepath) { File.expand_path('spec/fixtures/empty', PROJECT_ROOT) }

  describe "implementing the Puppetfile spec" do
    it "should implement 'branan/eight_hundred', '8.0.0'" do
      expect(described_class).to be_implement('branan/eight_hundred', '8.0.0')
    end

    it "should fail with an invalid full name" do
      expect(described_class).to_not be_implement('branan-eight_hundred', '8.0.0')
    end

    it "should fail with an invalid version" do
      expect(described_class).to_not be_implement('branan-eight_hundred', 'not a semantic version')
    end
  end

  describe "setting attributes" do
    subject { described_class.new('branan/eight_hundred', '/moduledir', '8.0.0') }

    its(:name) { should eq 'eight_hundred' }
    its(:author) { should eq 'branan' }
    its(:full_name) { should eq 'branan/eight_hundred' }
    its(:basedir) { should eq '/moduledir' }
    its(:full_path) { should eq '/moduledir/eight_hundred' }
  end

  describe "when syncing" do

    describe "and the module is in sync" do
      subject { described_class.new('branan/eight_hundred', fixture_modulepath, '8.0.0') }

      it { should be_insync }
      its(:version) { should eq '8.0.0' }
    end

    describe "and the desired version is newer than the installed version" do
      subject { described_class.new('branan/eight_hundred', fixture_modulepath, '80.0.0') }

      it { should_not be_insync }
      its(:version) { should eq 'v8.0.0' }

      it "should try to upgrade the module" do
        expected = %w{upgrade --version=80.0.0 --ignore-dependencies branan/eight_hundred}
        expect(subject).to receive(:pmt).with(expected)
        subject.sync
      end
    end

    describe "and the desired version is older than the installed version" do
      subject { described_class.new('branan/eight_hundred', fixture_modulepath, '7.0.0') }

      it { should_not be_insync }
      its(:version) { should eq '8.0.0' }

      it "should try to downgrade the module" do
        # Again with the magical "v" prefix to the version.
        expected = %w{upgrade --version=7.0.0 --ignore-dependencies branan/eight_hundred}
        expect(subject).to receive(:pmt).with(expected)
        subject.sync
      end
    end

    describe "and the module is not installed" do
      subject { described_class.new('branan/eight_hundred', empty_modulepath, '8.0.0') }

      it { should_not be_insync }
      its(:version) { should eq SemVer::MIN }

      it "should try to install the module" do
        expected = %w{install --version=8.0.0 --ignore-dependencies branan/eight_hundred}
        expect(subject).to receive(:pmt).with(expected)
        subject.sync
      end
    end
  end

  describe "determining the status" do
    subject { described_class.new('branan/eight_hundred', empty_modulepath, '8.0.0') }

    let(:metadata) do
      str = <<-EOD
{
  "checksums": {
    "Modulefile": "1e780d794bcd6629dc3006129fc02edf"
  },
  "license": "Apache License 2.0",
  "types": [

  ],
  "version": "8.0.0",
  "dependencies": [

  ],
  "summary": "800 modules! WOOOOOOO!",
  "source": "https://github.com/branan/puppet-module-eight_hundred",
  "description": "800 modules! WOOOOOOOOOOOOOOOOOO!",
  "author": "Branan Purvine-Riley",
  "name": "branan-eight_hundred",
  "project_page": "https://github.com/branan/puppet-module-eight_hundred"
}
      EOD
    end

    it "is :absent if the module directory is absent" do
      allow(File).to receive(:exist?).with(subject.full_path).and_return false
      expect(subject.status).to eq :absent
    end

    it "is :mismatched if there is no module metadata" do
      allow(File).to receive(:exist?).with(subject.full_path).and_return true
      allow(File).to receive(:exist?).with(subject.metadata_path).and_return false

      expect(subject.status).to eq :mismatched
    end

    it "is :mismatched if the metadata author doesn't match the expected author" do
      allow(File).to receive(:exist?).with(subject.full_path).and_return true
      allow(File).to receive(:exist?).with(subject.metadata_path).and_return true
      allow(File).to receive(:read).with(subject.metadata_path).and_return metadata

      allow(subject).to receive(:metadata_author).and_return 'blargh'

      expect(subject.status).to eq :mismatched
    end

    it "is :outdated if the metadata version doesn't match the expected version" do
      allow(File).to receive(:exist?).with(subject.full_path).and_return true
      allow(File).to receive(:exist?).with(subject.metadata_path).and_return true
      allow(File).to receive(:read).with(subject.metadata_path).and_return metadata

      allow(subject).to receive(:version).and_return '7.0.0'

      expect(subject.status).to eq :outdated
    end

    it "is :insync if the version and the author are in sync" do
      allow(File).to receive(:exist?).with(subject.full_path).and_return true
      allow(File).to receive(:exist?).with(subject.metadata_path).and_return true
      allow(File).to receive(:read).with(subject.metadata_path).and_return metadata

      expect(subject.status).to eq :insync
    end
  end
end
