require 'spec_helper'
require 'stringio'
require 'r10k/git'

describe R10K::Git::Alternates do
  subject { described_class.new("/some/nonexistent/path/.git") }

  it "interacts with the alternates file in the given git repository" do
    expect(subject.file.to_s).to eq("/some/nonexistent/path/.git/objects/info/alternates")
  end

  describe "reading alternate object entries" do
    it "reads the alternates file and splits on lines" do
      expect(subject.file).to receive(:file?).and_return true
      expect(subject.file).to receive(:readlines).and_return([
        "/var/cache/r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git\n",
        "/vagrant/.r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git\n",
      ])

      expect(subject.to_a).to eq([
        "/var/cache/r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git",
        "/vagrant/.r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git",
      ])
    end

    it "returns an empty array when the file is not present" do
      expect(subject.file).to receive(:file?).and_return false
      expect(subject.file).to receive(:readlines).never
      expect(subject.to_a).to eq([])
    end
  end

  describe "determining if an entry is already present" do
    before do
      allow(subject).to receive(:to_a).and_return([
        "/var/cache/r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git",
        "/vagrant/.r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git",
      ])
    end

    it "is true if the element is in the array of read entries" do
      expect(subject).to include("/vagrant/.r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git")
    end

    it "is false if the element is not in the array of read entries" do
      expect(subject).to_not include("/tmp/.r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git")
    end
  end

  describe "appending a new alternate object entry" do
    describe "and the git objects/info directory does not exist" do
      it "raises an error when the parent directory does not exist" do
        expect {
          subject << "/tmp/.r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git"
        }.to raise_error(R10K::Git::GitError,"Cannot write /some/nonexistent/path/.git/objects/info/alternates; parent directory does not exist")
      end
    end

    describe "and the git objects/info directory exists" do
      let(:io) { StringIO.new }

      before do
        expect(subject.file).to receive(:open).with('w').and_yield(io)
        subject.file.stub_chain(:parent, :directory?).and_return true
      end


      it "creates the alternates file with the new entry when not present" do
        expect(subject).to receive(:to_a).and_return([])
        subject << "/tmp/.r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git"

        expect(io.string).to eq("/tmp/.r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git\n")
      end

      it "rewrites the file with all alternate entries" do
        expect(subject).to receive(:to_a).and_return([
          "/var/cache/r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git",
          "/vagrant/.r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git",
        ])
        subject << "/tmp/.r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git"

        expect(io.string).to eq(<<-EOD)
/var/cache/r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git
/vagrant/.r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git
/tmp/.r10k/git/git---github.com-puppetlabs-puppetlabs-apache.git
        EOD
      end
    end
  end
end
