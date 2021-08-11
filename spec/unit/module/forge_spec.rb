require 'r10k/module/forge'
require 'spec_helper'

describe R10K::Module::Forge do
  # TODO: make these *unit* tests not depend on a real module on the real Forge :(

  include_context 'fail on execution'

  let(:fixture_modulepath) { File.expand_path('spec/fixtures/module/forge', PROJECT_ROOT) }
  let(:empty_modulepath) { File.expand_path('spec/fixtures/empty', PROJECT_ROOT) }

  describe "implementing the Puppetfile spec" do
    it "should implement 'branan/eight_hundred', '8.0.0'" do
      expect(described_class).to be_implement('branan/eight_hundred', { version: '8.0.0' })
    end

    it "should implement 'branan-eight_hundred', '8.0.0'" do
      expect(described_class).to be_implement('branan-eight_hundred', { version: '8.0.0' })
    end

    it "should fail with an invalid title" do
      expect(described_class).to_not be_implement('branan!eight_hundred', { version: '8.0.0' })
    end
  end

  describe "implementing the standard options interface" do
    it "should implement {type: forge}" do
      expect(described_class).to be_implement('branan-eight_hundred', {type: 'forge', version: '8.0.0', source: 'not implemented'})
    end
  end

  describe "setting attributes" do
    subject { described_class.new('branan/eight_hundred', '/moduledir', { version: '8.0.0' }) }

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
    subject { described_class.new('branan/eight_hundred', fixture_modulepath, { version: '8.0.0' }) }

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

  context "when a module is deprecated" do
    subject { described_class.new('puppetlabs/corosync', fixture_modulepath, { version: :latest }) }

    it "warns on sync if module is not already insync" do
      allow(subject).to receive(:status).and_return(:absent)

      allow(R10K::Forge::ModuleRelease).to receive(:new).and_return(double('mod_release', install: true))

      logger_dbl = double(Log4r::Logger)
      allow_any_instance_of(described_class).to receive(:logger).and_return(logger_dbl)

      allow(logger_dbl).to receive(:info).with(/Deploying module to.*/)
      allow(logger_dbl).to receive(:debug2).with(/No spec dir detected/)
      expect(logger_dbl).to receive(:warn).with(/puppet forge module.*puppetlabs-corosync.*has been deprecated/i)

      subject.sync
    end

    it "does not warn on sync if module is already insync" do
      allow(subject).to receive(:status).and_return(:insync)

      logger_dbl = double(Log4r::Logger)
      allow_any_instance_of(described_class).to receive(:logger).and_return(logger_dbl)

      allow(logger_dbl).to receive(:info).with(/Deploying module to.*/)
      allow(logger_dbl).to receive(:debug2).with(/No spec dir detected/)
      expect(logger_dbl).to_not receive(:warn).with(/puppet forge module.*puppetlabs-corosync.*has been deprecated/i)

      subject.sync
    end
  end

  describe '#expected_version' do
    it "returns an explicitly given expected version" do
      subject = described_class.new('branan/eight_hundred', fixture_modulepath, { version: '8.0.0' })
      expect(subject.expected_version).to eq '8.0.0'
    end

    it "uses the latest version from the forge when the version is :latest" do
      subject = described_class.new('branan/eight_hundred', fixture_modulepath, { version: :latest })
      release = double("Module Release", version: '8.8.8')
      expect(subject.v3_module).to receive(:current_release).and_return(release).twice
      expect(subject.expected_version).to eq '8.8.8'
    end

    it "throws when there are no available versions" do
      subject = described_class.new('branan/eight_hundred', fixture_modulepath, { version: :latest })
      expect(subject.v3_module).to receive(:current_release).and_return(nil)
      expect { subject.expected_version }.to raise_error(PuppetForge::ReleaseNotFound)
    end
  end

  describe "determining the status" do

    subject { described_class.new('branan/eight_hundred', fixture_modulepath, { version: '8.0.0' }) }

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

      allow(subject.instance_variable_get(:@metadata_file)).to receive(:read).and_return subject.metadata
      allow(subject.metadata).to receive(:full_module_name).and_return 'blargh-blargh'

      expect(subject.status).to eq :mismatched
    end

    it "is :outdated if the metadata version doesn't match the expected version" do
      allow(subject).to receive(:exist?).and_return true

      allow(subject.instance_variable_get(:@metadata_file)).to receive(:read).and_return subject.metadata
      allow(subject.metadata).to receive(:version).and_return '7.0.0'
      expect(subject.status).to eq :outdated
    end

    it "is :insync if the version and the author are in sync" do
      allow(subject).to receive(:exist?).and_return true

      expect(subject.status).to eq :insync
    end
  end

  describe "#sync" do
    subject { described_class.new('branan/eight_hundred', fixture_modulepath, { version: '8.0.0' }) }

    context "syncing the repo" do
      let(:module_org) { "coolorg" }
      let(:module_name) { "coolmod" }
      let(:title) { "#{module_org}-#{module_name}" }
      let(:dirname) { Pathname.new(Dir.mktmpdir) }
      let(:spec_path) { dirname + module_name + 'spec' }
      subject { described_class.new(title, dirname, {}) }

      it 'defaults to deleting the spec dir' do
        FileUtils.mkdir_p(spec_path)
        expect(subject).to receive(:status).and_return(:absent)
        expect(subject).to receive(:install)
        subject.sync
        expect(Dir.exist?(spec_path)).to eq false
      end
    end

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
      subject = described_class.new('branan/eight_hundred', fixture_modulepath, { version: '8.0.0' })
      release = instance_double('R10K::Forge::ModuleRelease')
      expect(R10K::Forge::ModuleRelease).to receive(:new).with('branan-eight_hundred', '8.0.0').and_return(release)
      expect(release).to receive(:install).with(subject.path)
      subject.install
    end
  end

  describe '#uninstall' do
    it 'removes the module path' do
      subject = described_class.new('branan/eight_hundred', fixture_modulepath, { version: '8.0.0' })
      expect(FileUtils).to receive(:rm_rf).with(subject.path.to_s)
      subject.uninstall
    end
  end

  describe '#reinstall' do
    it 'uninstalls and then installs the module' do
      subject = described_class.new('branan/eight_hundred', fixture_modulepath, { version: '8.0.0' })
      expect(subject).to receive(:uninstall)
      expect(subject).to receive(:install)
      subject.reinstall
    end
  end
end
