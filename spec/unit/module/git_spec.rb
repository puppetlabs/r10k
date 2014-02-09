require 'spec_helper'
require 'r10k/module/git'

describe R10K::Module::Git do

  describe "determining the status" do
    subject do
      described_class.new(
        'boolean',
        '/moduledir',
        {
          :git => 'git://github.com/adrienthebo/puppet-boolean'
        }
      )
    end

    it "is absent when the working dir is absent" do
      expect(subject.working_dir).to receive(:exist?).and_return false
      expect(subject.status).to eq :absent
    end

    it "is mismatched Then the working dir is not a git repository" do
      allow(subject.working_dir).to receive(:exist?).and_return true
      expect(subject.working_dir).to receive(:git?).and_return false
      expect(subject.status).to eq :mismatched
    end

    it "is mismatched when the expected remote does not match the actual remote" do
      allow(subject.working_dir).to receive(:exist?).and_return true
      expect(subject.working_dir).to receive(:git?).and_return true
      expect(subject.working_dir).to receive(:remote).and_return 'nope'
      expect(subject.status).to eq :mismatched
    end

    it "is outdated when the working dir is outdated" do
      allow(subject.working_dir).to receive(:exist?).and_return true
      expect(subject.working_dir).to receive(:git?).and_return true
      expect(subject.working_dir).to receive(:outdated?).and_return true
      expect(subject.status).to eq :outdated
    end

    it "is insync if all other conditions are satisfied" do
      allow(subject.working_dir).to receive(:exist?).and_return true
      expect(subject.working_dir).to receive(:git?).and_return true
      expect(subject.working_dir).to receive(:outdated?).and_return false
      expect(subject.status).to eq :insync
    end
  end
end
