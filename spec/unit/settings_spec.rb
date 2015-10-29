require 'spec_helper'
require 'r10k/settings'

describe R10K::Settings do
  describe "git settings" do
    subject { described_class.git_settings }

    describe "provider" do
      it "normalizes valid values to a symbol" do
        output = subject.evaluate("provider" => "rugged")
        expect(output[:provider]).to eq(:rugged)
      end
    end

    describe "username" do
      it "defaults to the current user" do
        expect(Etc).to receive(:getlogin).and_return("puppet")
        output = subject.evaluate({})
        expect(output[:username]).to eq("puppet")
      end

      it "passes values through unchanged" do
        output = subject.evaluate("username" => "git")
        expect(output[:username]).to eq("git")
      end
    end

    describe "private_key" do
      it "passes values through unchanged" do
        output = subject.evaluate("private_key" => "/etc/puppetlabs/r10k/id_rsa")
        expect(output[:private_key]).to eq("/etc/puppetlabs/r10k/id_rsa")
      end
    end
  end

  describe "forge settings" do
    subject { described_class.forge_settings }

    describe "proxy" do
      it "accepts valid URIs" do
        output = subject.evaluate("proxy" => "http://proxy.tessier-ashpool.freeside:3128")
        expect(output[:proxy]).to eq "http://proxy.tessier-ashpool.freeside:3128"
      end

      it "rejects invalid URIs" do
        expect {
          subject.evaluate("proxy" => "that's no proxy!")
        }.to raise_error do |err|
          expect(err.message).to match(/Validation failed for forge settings group/)
          expect(err.errors.size).to eq 1
          expect(err.errors[:proxy]).to be_a_kind_of(ArgumentError)
          expect(err.errors[:proxy].message).to match(/could not be parsed as a URL/)
        end
      end
    end

    describe "baseurl" do
      it "accepts valid URIs" do
        output = subject.evaluate("baseurl" => "https://forge.tessier-ashpool.freeside")
        expect(output[:baseurl]).to eq "https://forge.tessier-ashpool.freeside"
      end

      it "rejects invalid URIs" do
        expect {
          subject.evaluate("baseurl" => "that's no forge!")
        }.to raise_error do |err|
          expect(err.message).to match(/Validation failed for forge settings group/)
          expect(err.errors.size).to eq 1
          expect(err.errors[:baseurl]).to be_a_kind_of(ArgumentError)
          expect(err.errors[:baseurl].message).to match(/could not be parsed as a URL/)
        end
      end
    end
  end

  describe "deploy settings" do
    subject { described_class.deploy_settings }

    describe "write_lock" do
      it "accepts a string with a reason for the write lock" do
        output = subject.evaluate("write_lock" => "No maintenance window active, code freeze till 2038-01-19")
        expect(output[:write_lock]).to eq("No maintenance window active, code freeze till 2038-01-19")
      end

      it "accepts false and null values for the write lock" do
        output = subject.evaluate("write_lock" => false)
        expect(output[:write_lock]).to eq false
      end

      it "rejects non-string truthy values for the write lock" do
        expect {
          subject.evaluate("write_lock" => %w[list of reasons why deploys are locked])
        }.to raise_error do |err|
          expect(err.message).to match(/Validation failed for deploy settings group/)
          expect(err.errors.size).to eq 1
          expect(err.errors[:write_lock]).to be_a_kind_of(ArgumentError)
          expect(err.errors[:write_lock].message).to match(/should be a string containing the reason/)
        end
      end
    end
  end

  describe "global settings" do
    subject { described_class.global_settings }
    describe "sources" do
      it "passes values through unchanged" do
        output = subject.evaluate("sources" => {"puppet" => {"remote" => "https://git.tessier-ashpool.freeside"}})
        expect(output[:sources]).to eq({"puppet" => {"remote" => "https://git.tessier-ashpool.freeside"}})
      end
    end

    describe "cachedir" do
      it "passes values through unchanged" do
        output = subject.evaluate("cachedir" => "/srv/r10k/git")
        expect(output[:cachedir]).to eq("/srv/r10k/git")
      end
    end

    describe "postrun" do
      it "accepts an argument vector" do
        output = subject.evaluate("postrun" => ["curl", "-F", "deploy=done", "http://reporting.tessier-ashpool.freeside/r10k"])
        expect(output[:postrun]).to eq(["curl", "-F", "deploy=done", "http://reporting.tessier-ashpool.freeside/r10k"])
      end

      it "rejects a string command" do
        expect {
          subject.evaluate("postrun" => "curl -F 'deploy=done' https://reporting.tessier-ashpool.freeside/r10k")
        }.to raise_error do |err|
          expect(err.message).to match(/Validation failed for global settings group/)
          expect(err.errors.size).to eq 1
          expect(err.errors[:postrun]).to be_a_kind_of(ArgumentError)
          expect(err.errors[:postrun].message).to eq("The postrun setting should be an array of strings, not a String")
        end
      end
    end

    describe "git settings" do
      it "passes settings through to the git settings" do
        output = subject.evaluate("git" => {"provider" => "shellgit", "username" => "git"})
        expect(output[:git]).to eq(:provider => :shellgit, :username => "git", :private_key => nil, :repositories => {})
      end
    end

    describe "forge settings" do
      it "passes settings through to the forge settings" do
        output = subject.evaluate("forge" => {"baseurl" => "https://forge.tessier-ashpool.freeside", "proxy" => "https://proxy.tessier-ashpool.freesize:3128"})
        expect(output[:forge]).to eq(:baseurl => "https://forge.tessier-ashpool.freeside", :proxy => "https://proxy.tessier-ashpool.freesize:3128")
      end
    end
  end
end
