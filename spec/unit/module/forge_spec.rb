require 'r10k/module/forge'
require 'spec_helper'

describe R10K::Module::Forge do

  include_context 'fail on execution'

  let(:fixture_modulepath) { File.expand_path('spec/fixtures/module/forge', PROJECT_ROOT) }
  let(:empty_modulepath) { File.expand_path('spec/fixtures/empty', PROJECT_ROOT) }

  describe "implementing the Puppetfile spec" do
    it "should implement 'branan/eight_hundred', '8.0.0'" do
      expect(described_class).to be_implement('branan/eight_hundred', '8.0.0')
    end

    it "should implement 'branan-eight_hundred', '8.0.0'" do
      expect(described_class).to be_implement('branan-eight_hundred', '8.0.0')
    end

    it "should fail with an invalid title" do
      expect(described_class).to_not be_implement('branan!eight_hundred', '8.0.0')
    end
  end

  describe "setting attributes" do
    subject { described_class.new('branan/eight_hundred', '/moduledir', '8.0.0') }

    it "sets the name" do
      expect(subject.name).to eq 'eight_hundred'
    end

    it "sets the author" do
      expect(subject.author).to eq 'branan'
    end

    it "sets the dirname" do
      expect(subject.dirname).to eq '/moduledir'
    end

    it "sets the title" do
      expect(subject.title).to eq 'branan-eight_hundred'
    end
  end

  describe "properties" do
    subject { described_class.new('branan/eight_hundred', fixture_modulepath, '8.0.0') }

    it "sets the module type to :forge" do
      expect(subject.properties).to include(:type => :forge)
    end

    it "sets the expected version" do
      expect(subject.properties).to include(:expected => '8.0.0')
    end

    it "sets the actual version" do
      expect(subject).to receive(:current_version).and_return('0.8.0')
      expect(subject.properties).to include(:actual => '0.8.0')
    end
  end

  describe '#expected_version' do
    it "returns an explicitly given expected version" do
      subject = described_class.new('branan/eight_hundred', fixture_modulepath, '8.0.0')
      expect(subject.expected_version).to eq '8.0.0'
    end

    it "uses the latest version from the forge when the version is :latest" do
      subject = described_class.new('branan/eight_hundred', fixture_modulepath, :latest)
      expect(subject.v3_module).to receive_message_chain(:current_release, :version).and_return('8.8.8')
      expect(subject.expected_version).to eq '8.8.8'
    end
  end

  describe "determining the status" do

    subject { described_class.new('branan/eight_hundred', fixture_modulepath, '8.0.0') }

    it "is :absent if the module directory is absent" do
      allow(subject).to receive(:exist?).and_return false
      expect(subject.status).to eq :absent
    end

    it "is :mismatched if there is no module metadata" do
      allow(subject).to receive(:exist?).and_return true
      allow(File).to receive(:exist?).and_return false

      expect(subject.status).to eq :mismatched
    end

    it "is :mismatched if module was previously a git checkout" do
      allow(File).to receive(:directory?).and_return true

      expect(subject.status).to eq :mismatched
    end

    it "is :mismatched if the metadata author doesn't match the expected author" do
      allow(subject).to receive(:exist?).and_return true

      allow(subject.metadata).to receive(:full_module_name).and_return 'blargh-blargh'

      expect(subject.status).to eq :mismatched
    end

    it "is :outdated if the metadata version doesn't match the expected version" do
      allow(subject).to receive(:exist?).and_return true

      allow(subject.metadata).to receive(:version).and_return '7.0.0'
      expect(subject.status).to eq :outdated
    end

    it "is :insync if the version and the author are in sync" do
      allow(subject).to receive(:exist?).and_return true

      expect(subject.status).to eq :insync
    end
  end

  describe "#sync" do
    subject { described_class.new('branan/eight_hundred', fixture_modulepath, '8.0.0') }

    it 'does nothing when the module is in sync' do
      allow(subject).to receive(:status).and_return :insync

      expect(subject).to receive(:install).never
      expect(subject).to receive(:upgrade).never
      expect(subject).to receive(:reinstall).never
      subject.sync
    end

    it 'reinstalls the module when it is mismatched' do
      allow(subject).to receive(:status).and_return :mismatched
      expect(subject).to receive(:reinstall)
      subject.sync
    end

    it 'upgrades the module when it is outdated' do
      allow(subject).to receive(:status).and_return :outdated
      expect(subject).to receive(:upgrade)
      subject.sync
    end

    it 'installs the module when it is absent' do
      allow(subject).to receive(:status).and_return :absent
      expect(subject).to receive(:install)
      subject.sync
    end
  end

  describe '#install' do
    it 'installs the module from the forge' do
      subject = described_class.new('branan/eight_hundred', fixture_modulepath, '8.0.0')
      release = instance_double('R10K::Forge::ModuleRelease')
      expect(R10K::Forge::ModuleRelease).to receive(:new).with('branan-eight_hundred', '8.0.0').and_return(release)
      expect(release).to receive(:install).with(subject.path)
      subject.install
    end
  end

  describe '#uninstall' do
    it 'removes the module path' do
      subject = described_class.new('branan/eight_hundred', fixture_modulepath, '8.0.0')
      expect(FileUtils).to receive(:rm_rf).with(subject.path.to_s)
      subject.uninstall
    end
  end

  describe '#reinstall' do
    it 'uninstalls and then installs the module' do
      subject = described_class.new('branan/eight_hundred', fixture_modulepath, '8.0.0')
      expect(subject).to receive(:uninstall)
      expect(subject).to receive(:install)
      subject.reinstall
    end
  end
end
