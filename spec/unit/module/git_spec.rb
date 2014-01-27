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

    it "is mismatched then the working dir is not a git repository" do
      allow(subject.working_dir).to receive(:exist?).and_return true
      expect(subject.working_dir).to receive(:git?).and_return false
      expect(subject.status).to eq :mismatched
    end

    it "is outdated when the expected version doesn't match the actual version"

    it "is insync if all other conditions are satisfied" do
      allow(subject.working_dir).to receive(:exist?).and_return true
      allow(subject.working_dir).to receive(:git?).and_return true
      expect(subject.status).to eq :insync
    end
  end
end
