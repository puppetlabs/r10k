require 'r10k/module/forge'
require 'semver'
require 'spec_helper'

describe R10K::Module::Forge do
  before :each do
    Object.expects(:systemu).never
  end

  before :each do
    s = stub(:debug2 => nil, :debug1 => nil, :debug => nil, :info => nil)
    described_class.any_instance.stubs(:logger).returns s
  end

  describe "implementing the Puppetfile spec" do
    it "should implement 'branan/eight_hundred', '8.0.0'" do
      described_class.should be_implement('branan/eight_hundred', '8.0.0')
    end

    it "should fail with an invalid full name" do
      described_class.should_not be_implement('branan-eight_hundred', '8.0.0')
    end

    it "should fail with an invalid version" do
      described_class.should_not be_implement('branan-eight_hundred', 'not a semantic version')
    end
  end

  describe "setting attributes" do
    subject { described_class.new('branan/eight_hundred', '/moduledir', '8.0.0') }

    its(:name) { should eq 'eight_hundred' }
    its(:owner) { should eq 'branan' }
    its(:full_name) { should eq 'branan/eight_hundred' }
    its(:basedir) { should eq '/moduledir' }
    its(:full_path) { should eq '/moduledir/eight_hundred' }
  end

  describe "when syncing" do
    let(:fixture_modulepath) { File.expand_path('spec/fixtures/module/forge', PROJECT_ROOT) }
    let(:empty_modulepath) { File.expand_path('spec/fixtures/empty', PROJECT_ROOT) }

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
        # "v80.0.0" ? Seriously? Where did the "v" come from?
        expected = %w{upgrade --version=v80.0.0 --ignore-dependencies branan/eight_hundred}
        subject.expects(:pmt).with(expected)
        subject.sync
      end
    end

    describe "and the desired version is older than the installed version" do
      subject { described_class.new('branan/eight_hundred', fixture_modulepath, '7.0.0') }

      it { should_not be_insync }
      its(:version) { should eq 'v8.0.0' }

      it "should try to downgrade the module" do
        # Again with the magical "v" prefix to the version.
        expected = %w{upgrade --version=v7.0.0 --ignore-dependencies branan/eight_hundred}
        subject.expects(:pmt).with(expected)
        subject.sync
      end
    end

    describe "and the module is not installed" do
      subject { described_class.new('branan/eight_hundred', empty_modulepath, '8.0.0') }

      it { should_not be_insync }
      its(:version) { should eq SemVer::MIN }

      it "should try to install the module" do
        expected = %w{install --version=v8.0.0 --ignore-dependencies branan/eight_hundred}
        subject.expects(:pmt).with(expected)
        subject.sync
      end
    end
  end
end
