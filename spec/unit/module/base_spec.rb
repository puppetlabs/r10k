require 'spec_helper'
require 'r10k/module/base'

describe R10K::Module::Base do
  describe "parsing the title" do
    it "parses titles with no owner" do
      m = described_class.new('eight_hundred', '/moduledir', [])
      expect(m.name).to eq 'eight_hundred'
      expect(m.owner).to be_nil
    end

    it "parses forward slash separated titles" do
      m = described_class.new('branan/eight_hundred', '/moduledir', [])
      expect(m.name).to eq 'eight_hundred'
      expect(m.owner).to eq 'branan'
    end

    it "parses hyphen separated titles" do
      m = described_class.new('branan-eight_hundred', '/moduledir', [])
      expect(m.name).to eq 'eight_hundred'
      expect(m.owner).to eq 'branan'
    end

    it "raises an error when the title is not correctly formatted" do
      expect {
        described_class.new('branan!eight_hundred', '/moduledir', [])
      }.to raise_error(ArgumentError, "Module name (branan!eight_hundred) must match either 'modulename' or 'owner/modulename'")
    end
  end

  describe 'deleting the spec dir' do
    let(:module_org) { "coolorg" }
    let(:module_name) { "coolmod" }
    let(:title) { "#{module_org}-#{module_name}" }
    let(:dirname) { Pathname.new(Dir.mktmpdir) }
    let(:spec_path) { dirname + module_name + 'spec' }

    before(:each) do
      logger = double("logger")
      allow_any_instance_of(described_class).to receive(:logger).and_return(logger)
      allow(logger).to receive(:debug2).with(any_args)
      allow(logger).to receive(:info).with(any_args)
    end

    it 'does not remove the spec directory by default' do
      FileUtils.mkdir_p(spec_path)
      m = described_class.new(title, dirname, {})
      m.maybe_delete_spec_dir
      expect(Dir.exist?(spec_path)).to eq true
    end

    it 'detects a symlink and deletes the target' do
      Dir.mkdir(dirname + module_name)
      target_dir = Dir.mktmpdir
      FileUtils.ln_s(target_dir, spec_path)
      m = described_class.new(title, dirname, {exclude_spec: true})
      m.maybe_delete_spec_dir
      expect(Dir.exist?(target_dir)).to eq false
    end

    it 'removes the spec directory if exclude_spec is set' do
      FileUtils.mkdir_p(spec_path)
      m = described_class.new(title, dirname, {exclude_spec: true})
      m.maybe_delete_spec_dir
      expect(Dir.exist?(spec_path)).to eq false
    end

    it 'does not remove the spec directory if spec_deletable is false' do
      FileUtils.mkdir_p(spec_path)
      m = described_class.new(title, dirname, {})
      m.spec_deletable = false
      m.maybe_delete_spec_dir
      expect(Dir.exist?(spec_path)).to eq true
    end
  end

  describe "path variables" do
    it "uses the module name as the name" do
      m = described_class.new('eight_hundred', '/moduledir', [])
      expect(m.dirname).to eq '/moduledir'
      expect(m.path).to eq(Pathname.new('/moduledir/eight_hundred'))
    end

    it "does not include the owner in the path" do
      m = described_class.new('branan/eight_hundred', '/moduledir', [])
      expect(m.dirname).to eq '/moduledir'
      expect(m.path).to eq(Pathname.new('/moduledir/eight_hundred'))
    end
  end

  describe "with alternate variable names" do
    subject do
      described_class.new('branan/eight_hundred', '/moduledir', [])
    end

    it "aliases full_name to title" do
      expect(subject.full_name).to eq 'branan-eight_hundred'
    end

    it "aliases author to owner" do
      expect(subject.author).to eq 'branan'
    end

    it "aliases basedir to dirname" do
      expect(subject.basedir).to eq '/moduledir'
    end
  end

  describe "accepting a visitor" do
    subject { described_class.new('branan-eight_hundred', '/moduledir', []) }

    it "passes itself to the visitor" do
      visitor = spy('visitor')
      expect(visitor).to receive(:visit).with(:module, subject)
      subject.accept(visitor)
    end
  end
end
