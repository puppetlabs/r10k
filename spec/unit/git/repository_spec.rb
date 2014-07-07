require 'spec_helper'
require 'r10k/git'

describe R10K::Git::Repository do
  include_context "fail on execution"

  describe "remotes" do
    let(:output) do
      "cache	/home/user/.r10k/git/git@github.com-org-org-modules (fetch)\n" +
      "cache	/home/user/.r10k/git/git@github.com-org-org-modules (push)\n" +
      "origin	git@github.com:org/org-modules (fetch)\n" +
      "origin	git@github.com:org/org-modules (push)\n"
    end

    it "generates a hash of remote names and remote URLs" do
      expect(subject).to receive(:git).with(%w[remote -v], anything).and_return(double(:stdout => output))

      expect(subject.remotes).to eq({
        'cache'  => '/home/user/.r10k/git/git@github.com-org-org-modules',
        'origin' => 'git@github.com:org/org-modules',
      })
    end
  end

  describe "tags" do
    let(:tags) { %w[0.1.1 0.1.2 0.1.3 0.1.4 0.2.0 0.3.0 2.0.0] }
    let(:output) { tags.map {|x| x + "\n"}.join }

    it "returns a list of tags for this repo" do
      expect(subject).to receive(:git).with(%w[tag -l], anything).and_return(double(:stdout => output))
      expect(subject.tags).to eq(tags)
    end
  end
end
