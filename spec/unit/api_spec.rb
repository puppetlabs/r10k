require 'spec_helper'
require 'r10k/api'

RSpec.describe R10K::API do
  include_context "R10K::API"

  describe ".get_puppetfile" do
    let(:control_source_git) do
      { type: :git, remote: "git@github.com:puppetlabs/testing_control_repo.git" }
    end

    let(:control_source_svn) do
      { type: :svn, remote: "https://github.com/puppetlabs/testing_control_repo" }
    end

    before(:each) do
      @git_provider = class_double(R10K::API::Git)
      allow(R10K::API).to receive(:git).and_return(@git_provider)

      @svn_repo = instance_double(R10K::SVN::Remote)
      allow(R10K::SVN::Remote).to receive(:new).and_return(@svn_repo)
    end

    it "handles a base_path with a leading slash" do
      expect(@git_provider).to receive(:blob_at).with(anything, 'branch', 'puppet/Puppetfile', any_args)

      subject.get_puppetfile(control_source_git, 'branch', '/puppet')
    end

    it "handles a base_path with lots of leading slashes" do
      expect(@git_provider).to receive(:blob_at).with(anything, 'branch', 'puppet/Puppetfile', any_args)

      subject.get_puppetfile(control_source_git, 'branch', '//////puppet')
    end

    context "with a Git source" do
      it "calls #blob_at with expected values" do
        expect(@git_provider).to receive(:blob_at).with(anything, 'branch', 'Puppetfile', any_args)

        subject.get_puppetfile(control_source_git, 'branch')
      end
    end

    context "with an SVN source" do
      it "calls #cat with expected values for production env" do
        expect(@svn_repo).to receive(:cat).with('trunk/Puppetfile')

        subject.get_puppetfile(control_source_svn, 'production')
      end

      it "calls #cat with expected values for non-production env" do
        expect(@svn_repo).to receive(:cat).with('branches/branch/Puppetfile')

        subject.get_puppetfile(control_source_svn, 'branch')
      end
    end
  end

  describe ".parse_puppetfile" do
    before(:each) do
      @modules = [ { name: "mod1" }, { name: "mod2" } ]

      @builder = instance_double(R10K::API::ModulesArrayBuilder, :build => @modules)
      allow(R10K::API::ModulesArrayBuilder).to receive(:new).and_return(@builder)

      @parser = instance_double(R10K::Puppetfile::DSL)
      allow(R10K::Puppetfile::DSL).to receive(:new).and_return(@parser)
    end

    it "reads directly from stream when passed an IO" do
      @io = double(:io)
      @puppetfile_content = "Puppetfile from IO!"

      expect(@io).to receive(:read).and_return(@puppetfile_content)
      expect(@parser).to receive(:instance_eval).with(@puppetfile_content)

      expect(subject.parse_puppetfile(@io)).to eq(@modules)
    end

    it "parses directly as string when passed a non-IO" do
      @puppetfile_content = "Puppetfile from file!"

      expect(@parser).to receive(:instance_eval).with(@puppetfile_content)

      expect(subject.parse_puppetfile(@puppetfile_content)).to eq(@modules)
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

        expect(R10K::API).to receive(:parse_deployed_git_env).with(@path, hash_including(moduledir: @moduledir)).and_return(env_data)

        expect(subject.parse_deployed_env(@path, moduledir: @moduledir)).to eq({ environment: "production", mock: "envmap" })
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

        expect(R10K::API).to receive(:parse_deployed_svn_env).with(@path, hash_including(moduledir: @moduledir)).and_return(env_data)

        expect(subject.parse_deployed_env(@path, moduledir: @moduledir)).to eq({ environment: "production", mock: "envmap" })
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

  describe ".update_caches" do
    let(:base_cachedir) { "/this/base/cachedir" }

    it "calls update_cache on all module_sources" do
      module_source_f = {:source => "fountain", :type => :forge}
      module_source_g = {:source => "giddy", :type => :git}
      module_sources = [module_source_f, module_source_g]

      expect(R10K::API).to receive(:update_cache).with(module_source_f, hash_including(cachedir: base_cachedir)).and_return(true)
      expect(R10K::API).to receive(:update_cache).with(module_source_g, hash_including(cachedir: base_cachedir)).and_return(true)

      expect(subject.update_caches(module_sources, cachedir: base_cachedir)).to eq(true)
    end

    it "raises an error if module_sources doesn't respond to #each" do
      module_sources = "string_does_not_respond_to_each"
      expect { subject.update_caches(module_sources) }.to raise_error(RuntimeError, /must be a collection/i)
    end
  end

  describe ".update_cache" do
    let(:module_source_g) { {:source => "giddy", :type => :git} }
    let(:module_source_f) { {:source => "fountain", :type => :forge} }
    let(:module_source_s) { {:source => "svelte", :type => :svn} }
    let(:module_source_o) { {:source => "otter", :type => :other} }
    let(:base_cachedir) { "/this/base/cachedir" }

    it "calls update_git_cache for a git module_source" do
      remote_g = module_source_g[:source]

      expect(R10K::API).to receive(:update_git_cache).with(remote_g, hash_including(cachedir: base_cachedir)).and_return(true)

      expect(subject.update_cache(module_source_g, cachedir: base_cachedir)).to eq(true)
    end

    it "does nothing for a forge module_source" do
      expect(subject.update_cache(module_source_f)).to eq(nil)
    end

    it "raises a NotImplementedError for an svn module_source" do
      expect { subject.update_cache(module_source_s) }.to raise_error(NotImplementedError)
    end

    it "raises a RuntimeError for any other type module source" do
      expect { subject.update_cache(module_source_o) }.to raise_error(RuntimeError, /Unrecognized module source type/)
    end
  end

  describe ".update_git_cache" do
    let(:base_cachedir) {"/this/base/cachedir"}
    let(:remote_g) { "giddy" }
    let(:repo_cachedir_g) { "giddy_cachedir" }

    context "when cache directory already exists" do
      before(:each) do
        allow(File).to receive(:directory?).with(repo_cachedir_g).and_return(true)
      end

      it "calls the git fetch with expected git_dir argument" do
        expect(R10K::API).to receive(:cachedir_for_git_remote).with(remote_g, base_cachedir).and_return(repo_cachedir_g)

        expect(R10K::API::Git).to receive(:fetch).with(repo_cachedir_g, remote_g, anything).and_return(true)
        expect(subject.update_git_cache(remote_g, cachedir: base_cachedir)).to eq(true)
      end
    end

    context "when cache directory does not already exist" do
      before(:each) do
        allow(File).to receive(:directory?).with(repo_cachedir_g).and_return(false)
      end

      it "calls git clone" do
        expect(R10K::API).to receive(:cachedir_for_git_remote).with(remote_g, base_cachedir).and_return(repo_cachedir_g)

        expect(R10K::API::Git).to receive(:clone).with(repo_cachedir_g, remote_g, hash_including(bare: true)).and_return(true)
        expect(subject.update_git_cache(remote_g, cachedir: base_cachedir)).to eq(true)
      end
    end
  end

  describe ".resolve_environment" do
    it "should return env_map unchanged when already resolved" do
      already_resolved = unresolved_envmap.merge(resolved_at: Time.new)

      expect(R10K::API).to_not receive(:resolve_module)

      expect(subject.resolve_environment(already_resolved)).to eq(already_resolved)
    end

    it "should call resolve_module on each module" do
      module_names = unresolved_modules.collect { |m| m[:name] }

      module_names.each do |name|
        expect(R10K::API).to receive(:resolve_module).with(name, anything, anything).and_return(unresolved_envmap)
      end

      subject.resolve_environment(unresolved_envmap)
    end

    context "when one or more modules are unresolvable" do
      it "should still attempt to resolve every module" do
        module_names = unresolved_modules.collect { |m| m[:name] }
        unresolvable = module_names.sample

        module_names.each do |name|
          if name == unresolvable
            expect(R10K::API).to receive(:resolve_module).with(name, anything, anything).and_raise(R10K::API::Errors::UnresolvableError.new("arbitrarily unresolvable"))
          else
            expect(R10K::API).to receive(:resolve_module).with(name, anything, anything).and_return(unresolved_envmap)
          end
        end

        expect { subject.resolve_environment(unresolved_envmap) }.to raise_error(R10K::API::Errors::UnresolvableError)
      end

      it "should raise a single exception with all failed modules" do
        unresolvable_names = unresolved_modules.collect { |m| m[:name] }.sample(3)

        allow(R10K::API).to receive(:resolve_module).and_return(unresolved_envmap)

        unresolvable_names.each do |name|
          allow(R10K::API).to receive(:resolve_module).with(name, anything, anything).and_raise(R10K::API::Errors::UnresolvableError.new("arbitrarily unresolvable"))
        end

        expect { subject.resolve_environment(unresolved_envmap) }.to raise_error do |error|
          expect(error).to be_a(R10K::API::Errors::UnresolvableError)

          unresolvable_names.each do |name|
            expect(error.message).to match(Regexp.new(name, Regexp::IGNORECASE | Regexp::MULTILINE))
          end
        end
      end
    end

    it "should set resolved_at value" do
      allow(R10K::API).to receive(:resolve_module).and_return(unresolved_envmap)

      expect(subject.resolve_environment(unresolved_envmap)).to include(:resolved_at => an_instance_of(Time))
    end
  end

  describe ".resolve_module" do
    it "should fail if module doesn't exist in env_map" do
      expect { subject.resolve_module("noexist", unresolved_envmap) }.to raise_error(RuntimeError, /could not find module/i)
    end

    it "should delegate to resolve_git_module for :git type modules" do
      expect(R10K::API).to receive(:resolve_git_module).with(hash_including(name: 'acl'), anything)

      subject.resolve_module('acl', unresolved_envmap)
    end

    it "should delegate to resolve_forge_module for :forge type modules" do
      expect(R10K::API).to receive(:resolve_forge_module).with(hash_including(name: 'apache'), anything)

      subject.resolve_module('apache', unresolved_envmap)
    end

    it "should raise for unrecognized module types" do
      crazy_envmap = unresolved_envmap.merge(modules: [{name: 'crazy_type', type: 'banana'}])

      expect { subject.resolve_module('crazy_type', crazy_envmap) }.to raise_error(R10K::API::Errors::UnresolvableError, /unrecognized module source type/i)
    end

    it "should return a complete env_map on success" do
      initial_mod_count = unresolved_envmap[:modules].size

      allow(R10K::API).to receive(:resolve_git_module) { |mod, opts| mod.merge(resolved_version: 'resolved git!') }
      allow(R10K::API).to receive(:resolve_forge_module) { |mod, opts| mod.merge(resolved_version: 'resolved forge!') }

      after_resolution = subject.resolve_module('apache', unresolved_envmap)
      expect(after_resolution[:modules].size).to eq(initial_mod_count)
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

      it "should reset environment" do
        provider = class_double(R10K::API::Git)
        allow(R10K::API).to receive(:git).and_return(provider)
        allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)

        version = envmap[:version] = "base_repo_version"
        expect(provider).to receive(:reset).with(path, version, hash_including(hard: true, git_dir: cachedir))

        subject.write_env_base(envmap, path, opts)
      end

      context "when :clean option is true" do
        it "should clean environment" do
          envmap[:version] = "base_repo_version"

          provider = class_double(R10K::API::Git, reset: true)
          allow(R10K::API).to receive(:git).and_return(provider)
          allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)

          expect(provider).to receive(:clean).with(path, hash_including(force: true, git_dir: cachedir))

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

      it "should reset environment" do
        provider = class_double(R10K::API::Git)
        allow(R10K::API).to receive(:git).and_return(provider)
        allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)

        version = modules.find { |mod| mod[:name] == mod_name }[:resolved_version]
        expect(provider).to receive(:reset).with(path, version, hash_including(hard: true, git_dir: cachedir))

        subject.write_module(mod_name, envmap, path, opts)
      end

      context "when :clean option is true" do
        it "should clean environment" do
          provider = class_double(R10K::API::Git, reset: true)
          allow(R10K::API).to receive(:git).and_return(provider)
          allow(R10K::API).to receive(:cachedir_for_git_remote).and_return(cachedir)

          expect(provider).to receive(:clean).with(path, hash_including(force: true, git_dir: cachedir))

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
      it "calls get_cached_forge_module for a forge module" do
        opts = {cachedir: '/tmp'}
        env_map = {modules: [{name: 'amodule', resolved_version: '0.1.0', type: :forge, source: 'gozar-amodule'}]}
        mod = env_map[:modules][0]
        release_slug = [mod[:source], mod[:resolved_version]].join('-')
        cachedir = opts[:cachedir]

        allow(Dir).to receive(:mktmpdir)
        allow(PuppetForge::Unpacker).to receive(:unpack)
        expect(R10K::API).to receive(:get_cached_forge_release).with(release_slug, cachedir, false, {}).and_return('a_fake_unpack_dir_for_gozar')
        expect(subject.write_module(mod[:name], env_map, opts[:cachedir], opts)).to eq(true)
      end
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
