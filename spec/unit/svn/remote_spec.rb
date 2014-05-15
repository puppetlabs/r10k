require 'r10k'
require 'r10k/svn'

describe R10K::SVN::Remote do
  subject { described_class.new('https://svn-server.site/repo') }

  it "generates the trunk URL by appending '/trunk' to the base URL" do
    expect(subject.trunk).to eq 'https://svn-server.site/repo/trunk'
  end

  describe "retrieving branches" do
    let(:branches) do
      %[apache/\ndns/\nrobobutler/\nstaging/\n]
    end

    it "enumerates the /branches directory of the base URL" do
      allow(subject).to receive(:svn).with(['ls', 'https://svn-server.site/repo/branches']).and_return(branches)
      expect(subject.branches).to eq(%w[apache dns robobutler staging])
    end
  end
end
