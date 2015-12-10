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

  describe "extracting file contents" do
    it "returns contents at given path as string" do
      allow(subject).to receive(:svn).with(['cat', 'https://svn-server.site/repo/trunk/Puppetfile']).and_return("Puppetfile Contents")
      expect(subject.cat('trunk/Puppetfile')).to eq("Puppetfile Contents")
    end

    it "extracts file at specific revision when given" do
      allow(subject).to receive(:svn).with(['cat', '-r 20', 'https://svn-server.site/repo/trunk/Puppetfile']).and_return("Puppetfile Contents at r20")
      expect(subject.cat('trunk/Puppetfile', 20)).to eq("Puppetfile Contents at r20")
    end
  end
end
