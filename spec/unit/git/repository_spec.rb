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

      expect(subject.remotes).to eq(
        'cache'  => '/home/user/.r10k/git/git@github.com-org-org-modules',
        'origin' => 'git@github.com:org/org-modules',
      )
    end
  end
end
