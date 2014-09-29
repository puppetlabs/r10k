require 'spec_helper'
require 'r10k/svn/working_dir'

describe R10K::SVN::WorkingDir, "initializing" do
  let(:pathname) { Pathname.new("/some/imaginary/path") }
  it "stores the provided path" do
    subject = described_class.new(pathname)
    expect(subject.path).to eq Pathname.new("/some/imaginary/path")
  end

  describe "when auth is provided" do
    it "raises an error when only the username is provided" do
      expect {
        described_class.new(pathname, :username => "root")
      }.to raise_error(ArgumentError, "Both username and password must be specified")
    end

    it "raises an error when only the password is provided" do
      expect {
        described_class.new(pathname, :password => "hunter2")
      }.to raise_error(ArgumentError, "Both username and password must be specified")
    end

    it "does not raise an error when both username and password are provided" do
      o = described_class.new(pathname, :username => "root", :password => "hunter2")
      expect(o.username).to eq("root")
      expect(o.password).to eq("hunter2")
    end
  end
end

describe R10K::SVN::WorkingDir, "when authentication credentials are given" do
  let(:pathname) { Pathname.new("/some/imaginary/path") }
  subject { described_class.new(pathname, :username => "root", :password => "hunter2") }

  def check_args(args)
    expect(args).to include("--username")
    expect(args).to include("root")
    expect(args).to include("--password")
    expect(args).to include("hunter2")
  end

  it "invokes 'svn checkout' with the given credentials" do
    expect(subject).to receive(:svn) do |args, _|
      check_args(args)
    end
    subject.checkout('https://some.svn.url/trunk')
  end

  it "invokes 'svn update' with the given credentials" do
    expect(subject).to receive(:svn) do |args, _|
      check_args(args)
    end
    subject.update
  end
end
