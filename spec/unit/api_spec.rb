require 'spec_helper'
require 'r10k/api'

RSpec.describe R10K::API do
  describe ".get_puppetfile" do
    before(:each) do
      @git_repo = instance_double(R10K::Git.bare_repository)
      allow(R10K::Git.bare_repository).to receive(:new).and_return(@git_repo)

      @svn_repo = instance_double(R10K::SVN::Remote)
      allow(R10K::SVN::Remote).to receive(:new).and_return(@svn_repo)
    end

    it "handles a base_path with a leading slash" do
      expect(@git_repo).to receive(:blob_at).with('branch', 'puppet/Puppetfile')

      subject.get_puppetfile(:git, '/tmp/repo.git', 'branch', '/puppet')
    end

    it "handles a base_path with lots of leading slashes" do
      expect(@git_repo).to receive(:blob_at).with('branch', 'puppet/Puppetfile')

      subject.get_puppetfile(:git, '/tmp/repo.git', 'branch', '//////puppet')
    end

    context "with a Git source" do
      it "calls #blob_at with expected values" do
        expect(@git_repo).to receive(:blob_at).with('branch', 'Puppetfile')

        subject.get_puppetfile(:git, '/tmp/repo.git', 'branch')
      end
    end

    context "with an SVN source" do
      it "calls #cat with expected values for production env" do
        expect(@svn_repo).to receive(:cat).with('trunk/Puppetfile')

        subject.get_puppetfile(:svn, 'https://example.com/svn/puppet', 'production')
      end

      it "calls #cat with expected values for non-production env" do
        expect(@svn_repo).to receive(:cat).with('branches/branch/Puppetfile')

        subject.get_puppetfile(:svn, 'https://example.com/svn/puppet', 'branch')
      end
    end
  end

  describe ".parse_puppetfile" do
    before(:each) do
      @modules = [ { name: "mod1" }, { name: "mod2" } ]

      @builder = instance_double(R10K::API::EnvmapBuilder, :build => @modules)
      allow(R10K::API::EnvmapBuilder).to receive(:new).and_return(@builder)

      @parser = instance_double(R10K::Puppetfile::DSL)
      allow(R10K::Puppetfile::DSL).to receive(:new).and_return(@parser)
    end

    it "reads directly from stream when passed an IO" do
      @io = double(:io)
      @puppetfile_content = "Puppetfile from IO!"

      expect(@io).to receive(:read).and_return(@puppetfile_content)
      expect(@parser).to receive(:instance_eval).with(@puppetfile_content)

      expect(subject.parse_puppetfile(@io)).to eq({ :modules => @modules })
    end

    it "parses directly as string when passed a non-IO" do
      @puppetfile_content = "Puppetfile from file!"

      expect(@parser).to receive(:instance_eval).with(@puppetfile_content)

      expect(subject.parse_puppetfile(@puppetfile_content)).to eq({ :modules => @modules })
    end
  end

  describe ".parse_deployed_env" do
    let(:env_data) do
      { mock: "envmap" }
    end

    context "for a deployed Git env" do
      before(:each) do
        allow(File).to receive(:directory?).with(/\.git$/).and_return(true)
        allow(File).to receive(:directory?).with(/\.svn$/).and_return(false)
      end

      it "delegates to parse_deployed_git_env" do
        @path = "/tmp/environments/production"
        @moduledir = "mods"

        expect(R10K::API).to receive(:parse_deployed_git_env).with(@path, @moduledir).and_return(env_data)

        expect(subject.parse_deployed_env(@path, @moduledir)).to eq({ environment: "production", mock: "envmap" })
      end
    end

    context "for a deployed SVN env" do
      before(:each) do
        allow(File).to receive(:directory?).with(/\.svn$/).and_return(true)
        allow(File).to receive(:directory?).with(/\.git$/).and_return(false)
      end

      it "delegates to parse_deployed_svn_env" do
        @path = "/tmp/environments/production"
        @moduledir = "mods"

        expect(R10K::API).to receive(:parse_deployed_svn_env).with(@path, @moduledir).and_return(env_data)

        expect(subject.parse_deployed_env(@path, @moduledir)).to eq({ environment: "production", mock: "envmap" })
      end
    end
  end

  describe ".parse_deployed_git_evn" do
    pending
  end

  describe ".parse_deployed_svn_env" do
    pending
  end

  describe ".parse_deployed_module" do
    pending
  end
end
