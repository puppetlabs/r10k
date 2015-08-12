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
