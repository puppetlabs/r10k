require 'spec_helper'
require 'stringio'
require 'r10k/git'

describe R10K::Git::Alternates do
  subject { described_class.new(Pathname.new("/some/nonexistent/path/.git")) }

  it "interacts with the alternates file in the given git repository" do
    expect(subject.file.to_s).to eq("/some/nonexistent/path/.git/objects/info/alternates")
  end

  describe "reading alternate object entries" do
    it "reads the alternates file and splits on lines" do
      expect(subject.file).to receive(:file?).and_return true
      expect(subject.file).to receive(:readlines).and_return([
        "/var/cache/r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git\n",
        "/vagrant/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git\n",
      ])

      expect(subject.read).to eq([
        "/var/cache/r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git",
        "/vagrant/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git",
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
        "/var/cache/r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git",
        "/vagrant/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git",
      ])
    end

    it "is true if the element is in the array of read entries" do
      expect(subject).to include("/vagrant/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git")
    end

    it "is false if the element is not in the array of read entries" do
      expect(subject).to_not include("/tmp/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git")
    end
  end


  describe "writing alternate entries" do
    describe "and the git objects/info directory does not exist" do
      it "raises an error when the parent directory does not exist" do
        expect {
          subject.write(["/tmp/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git"])
        }.to raise_error(R10K::Git::GitError,"Cannot write /some/nonexistent/path/.git/objects/info/alternates; parent directory does not exist")
      end
    end

    describe "and the git objects/info directory exists" do
      let(:io) { StringIO.new }

      before do
        expect(subject.file).to receive(:open).with('w').and_yield(io)
        expect(subject.file).to receive_message_chain(:parent, :directory?).and_return true
      end

      it "creates the alternates file with the new entry when not present" do
        subject.write(["/tmp/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git"])
        expect(io.string).to eq("/tmp/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git\n")
      end

      it "rewrites the file with all alternate entries" do
        subject.write(["/var/cache/r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git",
                       "/vagrant/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git",
                       "/tmp/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git"])

        expect(io.string).to eq(<<-EOD)
/var/cache/r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git
/vagrant/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git
/tmp/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git
        EOD
      end
    end

    describe "appending a new alternate object entry" do
      it "re-writes the file with the new entry concatenated to the file" do
        expect(subject).to receive(:to_a).and_return(["/var/cache/r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git",
                                                       "/vagrant/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git"])

        expect(subject).to receive(:write).with(["/var/cache/r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git",
                                                 "/vagrant/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git",
                                                 "/tmp/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git"])

        subject.add("/tmp/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git")
      end
    end
  end

  describe "conditionally appending a new alternate object entry" do
    before do
      expect(subject).to receive(:read).and_return(%w[/var/cache/r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git])
    end

    it "adds the entry and returns true when the entry doesn't exist" do
      expect(subject).to receive(:write).with(["/var/cache/r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git",
                                               "/tmp/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git"])
      expect(subject.add?("/tmp/.r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git")).to eq true
    end

    it "doesn't modify the file and returns false when the entry exists" do
      expect(subject).to_not receive(:write)
      expect(subject.add?("/var/cache/r10k/git/https---github.com-puppetlabs-puppetlabs-apache.git")).to eq false
    end
  end
end
