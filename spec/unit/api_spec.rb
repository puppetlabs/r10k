require 'spec_helper'
require 'r10k/api'

RSpec.describe R10K::API do
  let(:cachedir) { "/tmp/r10k/cache" }

  let(:modules) do
    [
      { name: "git_module", type: "git", resolved_version: "git_version", },
      { name: "forge_module", type: "forge", resolved_version: "forge_version", },
      { name: "local_module", type: "local", resolved_version: "local_version", },
      { name: "crazy_town", type: "banana", resolved_version: "cavendish", },
    ]
  end

  let(:source) do
    { type: :git }
  end

  let(:envmap) do
    { source: source, modules: modules, fake: true }
  end

  let(:mock_fh) do
    instance_double("IO", write: true, close: true)
  end

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

  describe ".envmap_from_source" do
    pending
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

  describe ".parse_environmentdir" do
    it "calls parse_deployed_env on each dir in the path" do
      env_path = '/tmp/environments'
      parse_env_a = '/dir_a'
      parse_env_b = '/dir_b'
      deployed_envs = [parse_env_a, parse_env_b]
      mock_envmap_a = { :mock => :a_envmap }
      mock_envmap_b = { :mock => :b_envmap }
      mock_envmaps = [mock_envmap_a, mock_envmap_b]
      moduledir = "mods"
      allow(Dir).to receive(:glob).with(/#{env_path}/).and_return(deployed_envs)
      allow(File).to receive(:directory?).with(Regexp.union(deployed_envs)).and_return(true)
      expect(R10K::API).to receive(:parse_deployed_env).with(parse_env_a, moduledir).and_return(mock_envmap_a)
      expect(R10K::API).to receive(:parse_deployed_env).with(parse_env_b, moduledir).and_return(mock_envmap_b)
      expect(subject.parse_environmentdir(env_path, moduledir)).to eq(mock_envmaps)
    end

    it "returns an empty array if the environment dir is empty" do
      empty_env_path = '/tmp/no_environments'
      allow(Dir).to receive(:glob).with(/#{empty_env_path}/).and_return([])
      expect(subject.parse_environmentdir(empty_env_path)).to eq([])
    end
  end

  describe ".write_environment" do
    it "should invoke write_env_base once" do
      path = "/tmp"

      allow(R10K::API).to receive(:write_module).and_return(true)
      allow(File).to receive(:open).and_yield(mock_fh)

      expect(R10K::API).to receive(:write_env_base).once.with(envmap, path, anything).and_return(true)

      subject.write_environment(envmap, path)
    end

    it "should invoke write_module once for each module" do
      path = "/tmp"

      allow(R10K::API).to receive(:write_env_base).and_return(true)
      allow(File).to receive(:open).and_yield(mock_fh)

      modules.each do |mod|
        expect(R10K::API).to receive(:write_module).with(mod[:name], envmap, include(mod[:name]), anything).and_return(true)
      end

      subject.write_environment(envmap, path)
    end

    it "should write envmap to .r10k-deploy.json on completion" do
      envmap_json = JSON.pretty_generate(envmap)

      expect(mock_fh).to receive(:write).with(envmap_json).and_return(true)
      expect(File).to receive(:open).with(/\.r10k-deploy\.json/, anything).and_yield(mock_fh)

      allow(R10K::API).to receive(:write_env_base).and_return(true)
      allow(R10K::API).to receive(:write_module).and_return(true)

      subject.write_environment(envmap, '/tmp')
    end
  end

  describe ".write_env_base" do
    let(:path) { "/tmp/r10k/environments/production" }

    let(:opts) do
      { cachedir: cachedir }
    end

    it "should create path if needed" do
      allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)
      allow(R10K::API).to receive(:git).and_return(double(:git).as_null_object)

      expect(File).to receive(:directory?).with(path).and_return(false).ordered
      expect(FileUtils).to receive(:mkdir_p).with(path).ordered

      subject.write_env_base(envmap, path, opts)
    end

    context "for git-based control repos" do
      before(:each) do
        allow(File).to receive(:directory?).and_return(true)
      end

      it "should require a cachedir" do
        opts.delete(:cachedir)

        allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)
        allow(R10K::API).to receive(:git).and_return(double(:git).as_null_object)

        expect { subject.write_env_base(envmap, path, opts) }.to raise_error(RuntimeError, /required.*cachedir.*option/)
      end

      it "should reset environment" do
        provider = class_double(R10K::API::Git)
        allow(R10K::API).to receive(:git).and_return(provider)
        allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)

        version = envmap[:version] = "base_repo_version"
        expect(provider).to receive(:reset).with(version, hash_including(hard: true, git_dir: cachedir, work_tree: path))

        subject.write_env_base(envmap, path, opts)
      end

      context "when :clean option is true" do
        it "should clean environment" do
          envmap[:version] = "base_repo_version"

          provider = class_double(R10K::API::Git, reset: true)
          allow(R10K::API).to receive(:git).and_return(provider)
          allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)

          expect(provider).to receive(:clean).with(hash_including(force: true, excludes: array_including('.r10k-deploy.json'), git_dir: cachedir, work_tree: path))

          subject.write_env_base(envmap, path, opts.merge({clean: true}))
        end
      end

      context "when :clean option is false" do
        it "should not clean environment" do
          envmap[:version] = "base_repo_version"

          provider = class_double(R10K::API::Git, reset: true)
          allow(R10K::API).to receive(:git).and_return(provider)
          allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)

          expect(provider).to_not receive(:clean)

          subject.write_env_base(envmap, path, opts.merge({clean: false}))
        end
      end

      context "when :clean option is unset" do
        it "should not clean environment" do
          envmap[:version] = "base_repo_version"

          provider = class_double(R10K::API::Git, reset: true)
          allow(R10K::API).to receive(:git).and_return(provider)
          allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)

          expect(provider).to_not receive(:clean)

          subject.write_env_base(envmap, path, opts)
        end
      end
    end

    context "for svn-based control repos" do
      before(:each) do
        allow(File).to receive(:directory?).and_return(true)
      end

      it "should raise NotImplementedError" do
        envmap[:source][:type] = 'svn'

        expect { subject.write_env_base(envmap, path, opts) }.to raise_error(NotImplementedError)
      end
    end
  end

  describe ".write_module" do
    let(:mod_basepath) { "/tmp/r10k/environments/production/modules" }
    let(:opts) do
      { cachedir: cachedir }
    end

    it "should fail if requested module is not in envmap" do
      mod_name = "no_exist"
      path = File.join(mod_basepath, mod_name)

      expect { subject.write_module(mod_name, envmap, path, opts) }.to raise_error(RuntimeError, /not.*find.*module.*#{mod_name}/i)
    end

    it "should fail if requested module is not resolved in envmap" do
      unresolved_mods = modules.collect { |mod| mod.delete(:resolved_version) and mod }
      unresolved_envmap = envmap.merge({modules: unresolved_mods})

      mod_name = "git_module"
      path = File.join(mod_basepath, mod_name)

      expect { subject.write_module(mod_name, unresolved_envmap, path, opts) }.to raise_error(RuntimeError, /cannot.*write.*#{mod_name}.*not.*resolved/i)
    end

    it "should create path if needed" do
      mod_name = "git_module"
      path = File.join(mod_basepath, mod_name)

      allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)
      allow(R10K::API).to receive(:git).and_return(double(:git).as_null_object)

      expect(File).to receive(:directory?).with(path).and_return(false).ordered
      expect(FileUtils).to receive(:mkdir_p).with(path).ordered

      subject.write_module(mod_name, envmap, path, opts)
    end

    it "should fail for unrecognized module types" do
      mod_name = "crazy_town"
      path = File.join(mod_basepath, mod_name)

      allow(File).to receive(:directory?).and_return(true)

      expect { subject.write_module(mod_name, envmap, path, opts) }.to raise_error(NotImplementedError)
    end

    context "for git-based modules" do
      let(:mod_name) { "git_module" }
      let(:path) { File.join(mod_basepath, mod_name) }

      before(:each) do
        allow(File).to receive(:directory?).and_return(true)
      end

      it "should require a cachedir" do
        opts.delete(:cachedir)

        allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)
        allow(R10K::API).to receive(:git).and_return(double(:git).as_null_object)

        expect { subject.write_module(mod_name, envmap, path, opts) }.to raise_error(RuntimeError, /required.*cachedir.*option/)
      end

      it "should reset environment" do
        provider = class_double(R10K::API::Git)
        allow(R10K::API).to receive(:git).and_return(provider)
        allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)

        version = modules.find { |mod| mod[:name] == mod_name }[:resolved_version]
        expect(provider).to receive(:reset).with(version, hash_including(hard: true, git_dir: cachedir, work_tree: path))

        subject.write_module(mod_name, envmap, path, opts)
      end

      context "when :clean option is true" do
        it "should clean environment" do
          provider = class_double(R10K::API::Git, reset: true)
          allow(R10K::API).to receive(:git).and_return(provider)
          allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)

          expect(provider).to receive(:clean).with(hash_including(force: true, git_dir: cachedir, work_tree: path))

          subject.write_module(mod_name, envmap, path, opts.merge({clean: true}))
        end
      end

      context "when :clean option is false" do
        it "should not clean environment" do
          provider = class_double(R10K::API::Git, reset: true)
          allow(R10K::API).to receive(:git).and_return(provider)
          allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)

          expect(provider).to_not receive(:clean)

          subject.write_module(mod_name, envmap, path, opts.merge({clean: false}))
        end
      end

      context "when :clean option is unset" do
        it "should not clean environment" do
          provider = class_double(R10K::API::Git, reset: true)
          allow(R10K::API).to receive(:git).and_return(provider)
          allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)

          expect(provider).to_not receive(:clean)

          subject.write_module(mod_name, envmap, path, opts)
        end
      end
    end

    context "for forge-based modules" do
      pending
    end

    context "for local modules" do
      pending
    end
  end


  describe ".parse_deployed_git_env" do
    pending
  end

  describe ".parse_deployed_svn_env" do
    pending
  end

  describe ".parse_deployed_module" do
    pending
  end
end
