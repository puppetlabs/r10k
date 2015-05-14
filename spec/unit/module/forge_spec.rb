require 'r10k/module/forge'
require 'r10k/semver'
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
      expect(subject.title).to eq 'branan/eight_hundred'
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

  describe "when syncing" do
    let(:metadata) do
      double('metadata',
             :exist? => true,
             :author => 'branan',
             :version => '8.0.0')
    end

    subject { described_class.new('branan/eight_hundred', fixture_modulepath, '8.0.0') }

    describe "and the module is in sync" do
      before do
        allow(subject).to receive(:status).and_return :insync
      end

      it "is in sync" do
        expect(subject).to be_insync
      end

      it "doesn't act when syncing anything" do
        expect(subject).to receive(:install).never
        expect(subject).to receive(:upgrade).never
        expect(subject).to receive(:reinstall).never
        subject.sync
      end
    end

    describe "and the module is mismatched" do
      before do
        allow(subject).to receive(:status).and_return :mismatched
      end

      it "is not in sync" do
        expect(subject).to_not be_insync
      end

      it "reinstalls the module" do
        expect(subject).to receive(:reinstall)
        subject.sync
      end

      it "reinstalls by removing the existing directory and calling the module tool" do
        expect(FileUtils).to receive(:rm_rf)
        expect(subject).to receive(:pmt) do |args|
          expect(args).to include 'install'
          expect(args).to include '--version=8.0.0'
          expect(args).to include 'branan/eight_hundred'
        end

        subject.sync
      end
    end

    describe "and the module is outdated" do
      before do
        allow(subject).to receive(:status).and_return :outdated
      end

      it "is not in sync" do
        expect(subject).to_not be_insync
      end

      it "upgrades the module" do
        expect(subject).to receive(:upgrade)
        subject.sync
      end

      it "upgrades by calling the module tool" do
        expect(subject).to receive(:pmt) do |args|
          expect(args).to include 'upgrade'
          expect(args).to include '--version=8.0.0'
          expect(args).to include 'branan/eight_hundred'
        end

        subject.sync
      end
    end

    describe "and the module is not installed" do
      before do
        allow(subject).to receive(:status).and_return :absent
      end

      it "is not in sync" do
        expect(subject).to_not be_insync
      end

      it "installs the module" do
        expect(subject).to receive(:uninstall).never
        expect(subject).to receive(:install)
        subject.sync
      end

      it "installs by calling the module tool" do
        expect(subject).to receive(:pmt) do |args|
          expect(args).to include 'install'
          expect(args).to include '--version=8.0.0'
          expect(args).to include 'branan/eight_hundred'
        end

        subject.sync
      end
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

  describe "and the expected version is :latest" do
    subject { described_class.new('branan/eight_hundred', fixture_modulepath, :latest) }

    let(:module_repository) { instance_double('R10K::ModuleRepository::Forge') }

    before do
      expect(R10K::ModuleRepository::Forge).to receive(:new).and_return module_repository
    end

    it "sets the expected version based on the latest forge version" do
      expect(module_repository).to receive(:latest_version).with('branan/eight_hundred').and_return('8.0.0')
      allow(subject).to receive(:exist?).and_return true
      allow(subject.metadata).to receive(:version).and_return '7.0.0'
      expect(subject.status).to eq :outdated
      expect(subject.expected_version).to eq '8.0.0'
    end
  end
end
