require 'r10k/api/envmap_builder'
require 'r10k/api/git'

require 'r10k/logging'
require 'r10k/git'
require 'r10k/git/errors'

require 'r10k/svn/remote'

require 'r10k/puppetfile'

require 'puppet_forge'
require 'semantic_puppet'

module R10K
  # A low-level interface for triggering r10k operations.
  #
  # @example Parse a Puppetfile and deploy the environment it represents:
  #   # Given "ops_source" is an instance of R10K::Source
  #   puppetfile = R10K::API.get_puppetfile(ops_source.type, ops_source.cache.path, "production")
  #   envmap = R10K::API.parse_puppetfile(puppetfile)
  #
  #   R10K::API.module_sources_for_environment(envmap).each do |src|
  #     R10K::API.update_cache(src)
  #   end
  #
  #   envmap = R10K::API.resolve_environment(envmap)
  #
  #   R10K::API.write_environment(envmap, ops_source.path_for("production"))
  #
  module API
    extend R10K::Logging

    class UnresolvableError < StandardError
      def initialize(message, modules=nil)
        if modules && modules.respond_to?(:each)
          modules.each { |m| message << "\n#{m[:name]} could not be resolved: #{m[:error].message}" }
        end

        super(message)
      end
    end


    # TODO: split functions up into submodules and extend those instead?
    # Everything that follows is a module_function until we get to some privates at the end.
    module_function

    # Returns the contents of Puppetfile inside the given control repo source at the given version. Assumes source repo cache has already been updated if applicable.
    #
    # @param source_type [:git, :svn] Format of control repo source.
    # @param source_cache_or_remote [String] Path to Git control repo cache or URL of SVN remote.
    # @param version [String] Commit-ish reference to the version of the Puppetfile to extract. (For Git repos, accepts anything rev-parse would understand, e.g. "abc123", "production", "1.0.3", etc. For SVN repos, must be a branch name.)
    # @param base_path [String] Path, relative to the root of the control repo, at which the Puppetfile can be found.
    # @return [String] Return contents of Puppetfile at given commit, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def get_puppetfile(source_type, source_cache_or_remote, version, base_path="")
      # Strip the leading slash to make a path relative to the root of the repo.
      puppetfile_path = File.join(base_path, "Puppetfile").sub(/^\/+/, '')

      case source_type.to_sym
      when :git
        return R10K::Git.bare_repository.new(source_cache_or_remote, '').blob_at(version, puppetfile_path)
      when :svn
        if version == 'production'
          repo_path = "trunk/#{puppetfile_path}"
        else
          repo_path = "branches/#{version}/#{puppetfile_path}"
        end

        return R10K::SVN::Remote.new(source_cache_or_remote).cat(repo_path)
      end
    end

    # Creates the modules portion of an abstract environment hashmap from the given Puppetfile.
    #
    # @param io_or_path [#read, String] A readable stream or String of Puppetfile contents.
    # @return [Hash] A hashmap representing the desired state of modules as specified in the passed in Puppetfile.
    # @raise RuntimeError
    def parse_puppetfile(io_or_content)
      builder = R10K::API::EnvmapBuilder.new
      parser = R10K::Puppetfile::DSL.new(builder)

      if io_or_content.respond_to?(:read)
        parser.instance_eval(io_or_content.read)
      else
        parser.instance_eval(io_or_content)
      end

      return { :modules => builder.build }
    end

    # Create an unresolved environment hashmap representing the desired state of a Puppet environment based on a source and branch.
    #
    # @param source [Hash] A hashmap representing a control repo source (like would be defined in r10k.yaml)
    # @param branch_name [String] Branch in the control repo to build an envmap for.
    # @param base_cachedir [String] Root of where r10k is caching things.
    # @return [Hash] A hashmap representing the desired state of the environment matching the given branch in the given source.
    # @raise [NotImplementedError] Control repo source has a type that is not currently supported.
    # @raise [RuntimeError] Something bad happened, see exception message.
    def envmap_from_source(source, branch_name, base_cachedir)
      # TODO: enforce valid Puppet environment name here?
      env_name = branch_name
      env_name = "#{source[:prefix]}_#{env_name}" if source[:prefix]

      case source[:type].to_sym
      when :git
        cachedir = cachedir_for_git_remote(source[:remote], base_cachedir)

        begin
          version = git.rev_parse(branch_name, git_dir: cachedir)
        rescue R10K::Git::GitError => e
          raise RuntimeError.new("Unable to resolve branch name '#{branch_name}' to a Git commit: #{e.message}")
        end

        # TODO: figure out how to pass through base_path option
        puppetfile = get_puppetfile(:git, cachedir, version)
      when :svn
        raise NotImplementedError
      else
        raise RuntimeError.new("Unrecognized control repo source type: #{source[:type]}")
      end

      envmap = {
        environment: env_name,
        source: source,
        version: version,
        resolved_at: nil,
      }

      envmap.merge(parse_puppetfile(puppetfile))
    end

    # Creates a resolved environment hashmap representing the actual state of the Puppet environment found at the given path.
    #
    # @param path [String] Path on disk of the Puppet environment to be inspected.
    # @param moduledir [String] The path, relative to the environment path, where the modules are deployed.
    # @return [Hash] A hashmap representing the actual state of the environment found at path.
    # @raise RuntimeError
    def parse_deployed_env(path, moduledir="modules")
      env_name = path.split(File::SEPARATOR).last

      # TODO: set :deployed_version for all deployed modules

      env_data = case
      when File.directory?(File.join(path, '.git')) then parse_deployed_git_env(path, moduledir)
      when File.directory?(File.join(path, '.svn')) then parse_deployed_svn_env(path, moduledir)
      else
        raise RuntimeError, "unrecognized deployed environment format"
      end

      return { :environment => env_name }.merge(env_data)
    end

    # Discover every Puppet environment under the given path and return a single hashmap containing the actual state
    # of every environment found.
    #
    # @param path [String] Path on disk to search for Puppet environments.
    # @param moduledir [String] The path, relative to the environment path, where the modules are deployed.
    # @return [Array<Hash>] An array of hashmaps, each representing the actual state of a single environment found in environmentdir.
    def parse_environmentdir(path, moduledir="modules")
      deployed_env_states = []

      if path
        deployed_envs = Dir.glob(File.join(path, '*')).select {|f| File.directory? f}
        deployed_envs.each do |env_dir|
          deployed_env_states << parse_deployed_env(env_dir, moduledir)
        end
      end

      return deployed_env_states
    end

    # Return a single module_source hashmap for the given module_name from the given env_map.
    #
    # @param module_name [String] The name of the module to build a module_source map for. Should match the "name" key of the target module in the env_map.
    # @param env_map [Hash] A hashmap representing a single environment's desired state.
    # @return [Hash] A hashmap representing the type (:vcs or :forge) and location of the given module's source.
    def module_source_for_module(module_name, env_map)
    end

    # Return an array of all remote sources referenced by module declarations within the given environment hashmap.
    #
    # @param env_map [Hash] A hashmap representing a single environment's state.
    # @return [Array<Hash>] An array of hashes, each hash represents the type (:vcs or :forge) and location of a single remote module source.
    def module_sources_for_environment(env_map)
    end

    # Update local cache represented by the given module_source hashmap.
    #
    # @param module_source [Hash] A hashmap representing a single remote module source (as produced by {#module_sources_for_environment})
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def update_cache(module_source)
    end

    # Update local cache of the given remote VCS repository.
    #
    # @param remote [String] URI for the remote repository which should be cached or updated.
    # @param opts [Hash] Additional options as defined.
    # @option opts [String] :cachedir Base path where caches are stored.
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def update_vcs_cache(remote, opts={})
    end

    # Update local cache of the given module from the Puppet Forge.
    #
    # @param module_slug [String] Hyphen separated namespace and module name of the module to be cached or updated. (E.g. "puppetlabs-apache")
    # @param opts [Hash] Additional options as defined.
    # @option opts [String] :cachedir Base path where caches are stored.
    # @option opts [String] :proxy An optional proxy server to use when downloading modules from the Forge.
    # @option opts [String] :baseurl The URL to the Puppet Forge to use for downloading modules.
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def update_forge_cache(module_slug, opts={})
    end

    # Given an environment map, returns a new environment map with any ambiguous module versions (e.g. branch names, version ranges, etc.)
    # resolved to specific versions (or commit SHAs).
    #
    # If passed an already resolved environment, this function will have no effect.
    #
    # This function assumes that all relevant caches have already been updated.
    #
    # @param env_map [Hash] A hashmap representing a single environment's desired state.
    # @return [Hash] A copy of env_map with :resolved_version key/value pairs added to each module and a :resolved_at timestamp added.
    # @raise [R10K::API::UnresolvableError] The env_map could not be fully resolved.
    def resolve_environment(env_map, opts={})
      # Return already resolved envmaps unchanged.
      return env_map if env_map[:resolved_at]

      # Deep copy of modules list to iterate over.
      unresolved = env_map[:modules].map { |mod| mod.dup }

      # Capture any unresolvable modules so we can report them all at once.
      unresolvable = []

      unresolved.each do |mod|
        begin
          env_map = resolve_module(mod[:name], env_map, opts)
        rescue R10K::API::UnresolvableError => e
          unresolvable << mod.merge(:error => e)
        end
      end

      unless unresolvable.empty?
        raise R10K::API::UnresolvableError.new("The given environment map contains errors that prevent it from being fully resolved.", unresolvable)
      end

      env_map[:resolved_at] = Time.new

      return env_map
    end

    # Given a module_name and an env_map, resolve any ambiguity in the specified module's version. (All other modules in the env_map will be unchanged.)
    #
    # This function assumes that the relevant module cache has already been updated.
    #
    # @param module_name [String] Name of the module to be resolved, should match the value of the "name" key in the supplied environment map.
    # @param env_map [Hash] A hashmap representing a single environment's desired state.
    # @param opts [Hash] Additional options as defined.
    # @option opts [String] :cachedir Base path where caches are stored.
    # @return [Hash] A copy of env_map with a new :resolved_version key/value pair added for the specified module.
    # @raise [RuntimeError, R10K::API::UnresolvableError] Something bad happened.
    def resolve_module(module_name, env_map, opts={})
      mod_found = false

      env_map[:modules].map! do |mod|
        if mod[:name] == module_name
          mod = case mod[:type].to_sym
          when :git
            resolve_git_module(mod, opts)
          when :forge
            resolve_forge_module(mod, opts)
          when :svn
            raise NotImplementedError
          when :local
            raise NotImplementedError
          else
            raise UnresolvableError.new("Unable to resolve '#{module_name}', unrecognized module source type '#{mod[:type]}'.")
          end

          mod_found = true
        end

        # We are mapping over the modules so we need let the module we just checked be the result of the block.
        mod
      end

      unless mod_found
        raise RuntimeError.new("Could not find module named '#{module_name}' in supplied environment map.")
      end

      return env_map
    end

    # Given an environment map, write the base environment and all Puppetfile declared modules to disk at the given path.
    #
    # @param env_map [Hash] A fully-resolved (see {#resolve_environment}) hashmap representing a single environment's new state.
    # @param path [String] Path on disk into which the given environment should be deployed. The given path should already include the environment's name. (e.g. /puppet/environments/production not /puppet/environments) Path will be created if it does not already exist.
    # @param opts [Hash] Additional options as defined.
    # @option opts [String] :cachedir Base path where caches are stored.
    # @option opts [Boolean] :clean Remove untracked files after write.
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def write_environment(env_map, path, opts={})
      write_env_base(env_map, path, opts)

      env_map[:modules].each do |m|
        # TODO: Pass through moduledir
        write_module(m[:name], env_map, File.join(path, 'modules', m[:name]), opts)
      end

      # TODO: Decide whether we want to do this here
      File.open(File.join(path, '.r10k-deploy.json'), 'w') do |fh|
        fh.write(JSON.pretty_generate(env_map))
      end

      return true
    end

    # Given an environment map, write the base environment only (not any Puppetfile declared modules) to disk at the given path.
    #
    # @param env_map [Hash] A fully-resolved (see {#resolve_environment}) hashmap representing a single environment's new state.
    # @param path [String] Path on disk into which the given environment should be deployed. The given path should already include the environment's name. (e.g. /puppet/environments/production not /puppet/environments) Path will be created if it does not already exist.
    # @param opts [Hash] Additional options as defined.
    # @option opts [String] :cachedir Base path where caches are stored.
    # @option opts [Boolean] :clean Remove untracked files in path after writing environment?
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def write_env_base(env_map, path, opts={})
      if !File.directory?(path)
        FileUtils.mkdir_p(path)
      end

      case env_map[:source][:type].to_sym
      when :git
        if !opts[:cachedir]
          raise RuntimeError.new("A value is required for the :cachedir option when deploying an environment from a git source.")
        end

        cachedir = cachedir_for_git_remote(env_map[:source][:remote], opts[:cachedir])

        git.reset(env_map[:version], hard: true, git_dir: cachedir, work_tree: path)

        if opts[:clean]
          git.clean(force: true, excludes: ['.r10k-deploy.json'], git_dir: cachedir, work_tree: path)
        end
      else
        raise NotImplementedError
      end

      return true
    end

    # Write the given module, using the version/commit declared in the given environment map, to disk at the given path.
    #
    # @param module_name [String] Name of the module to be written to disk, should match the value of the "name" key in the supplied environment map.
    # @param env_map [Hash] A fully-resolved (see {#resolve_environment}) hashmap representing a single environment's new state.
    # @param path [String] Path on disk into which the given module should be deployed. The given path should already include the environment and module names. (e.g. /puppet/environments/production/modules/apache) Path will be created if it does not already exist.
    # @param opts [Hash] Additional options as defined.
    # @option opts [String] :cachedir Base path where caches are stored.
    # @option opts [Boolean] :clean Remove untracked files in path after writing module?
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def write_module(module_name, env_map, path, opts={})
      mod = env_map[:modules].find { |m| m[:name] == module_name }

      if mod.nil?
        raise RuntimeError.new("Could not find module named '#{module_name}' in supplied environment map.")
      end

      if !mod[:resolved_version]
        raise RuntimeError.new("Cannot write module '#{module_name}' from an environment map which is not fully resolved.")
      end

      if !File.directory?(path)
        FileUtils.mkdir_p(path)
      end

      # TODO: Safety/santity check on path?

      case mod[:type].to_sym
      when :git
        if !opts[:cachedir]
          raise RuntimeError.new("A value is required for the :cachedir option when deploying a module from a git source.")
        end

        cachedir = cachedir_for_git_remote(mod[:source], opts[:cachedir])

        git.reset(mod[:resolved_version], hard: true, git_dir: cachedir, work_tree: path)

        if opts[:clean]
          git.clean(force: true, git_dir: cachedir, work_tree: path)
        end
      when :forge
        if !opts[:cachedir]
          raise RuntimeError.new("A value is required for the :cachedir option when deploying a module from a Forge source.")
        end

        cachedir = cachedir_for_forge_module(mod[:source], opts[:cachedir])

        # TODO: cache tarball

        # TODO: use PuppetForge::Unpacker?
        raise NotImplementedError
      else
        raise NotImplementedError
      end

      return true
    end

    # Remove any deployed environments from the given path that do not exist in the given environment list.
    #
    # @param base_path [String] Path on disk to the base environmentdir from which to remove environments.
    # @param env_list [Array<String>] Array of environment names which should NOT be purged.
    # @param opts [Hash] Additional options as defined.
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def purge_unmanaged_environments(base_path, env_list, opts={})
    end

    # Remove any deployed modules from the given path that do not exist in the given environment map.
    #
    # @param env_path [String] Path on disk to the deployed environment described by env_map.
    # @param env_map [Hash] An abstract or resolved environment map.
    # @param opts [Hash] Additional options as defined.
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def purge_unmanaged_modules(env_path, env_map, opts={})
    end


    # End-to-end integrated functions.

    # Deploy an environment and all its modules into the given path, automatically updating module sources as needed.
    #
    # @param env_map [Hash] An abstract or resolved environment map.
    # @param path [String] Path on disk into which the given environment should be deployed. The given path should already include the environment's name. (e.g. /puppet/environments/production not /puppet/environments) Path will be created if it does not already exist.
    # @param opts [Hash] Additional options as defined.
    # @option opts [Boolean] :purge Whether or not to purge unmanaged modules in the given environment path after deploy. Default: false
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def deploy_environment(env_map, path, opts={})
      R10K::API.module_sources_for_environment(env_map).each do |src|
        R10K::API.update_cache(src)
      end

      env_map = R10K::API.resolve_environment(env_map)

      R10K::API.write_environment(env_map, path, opts)

      if opts[:purge]
        R10K::API.purge_unmanaged_modules(path, env_map)
      end
    end

    # Deploy a single module into a given environment path, updating module cache as needed.
    #
    # @param module_name [String] Name of the module to be deployed, should match the value of the "name" key in the supplied environment map.
    # @param env_map [Hash] A hashmap representing a single environment's desired state.
    # @param path [String] Path on disk to the environment into which the given module should be deployed. The given path should already include the environment's name. (e.g. /puppet/environments/production not /puppet/environments) Path will be created if it does not already exist.
    # @param opts [Hash] Additional options as defined.
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def deploy_module_into_env(module_name, env_map, path, opts={})
      R10K::API.update_cache(R10K::API.module_source_for_module(module_name, env_map))

      env_map = R10K::API.resolve_module(module_name, env_map)

      R10K::API.write_module(module_name, env_map, path)
    end

    private

    # Shortcut to the Git command wrapper.
    def self.git
      R10K::API::Git
    end
    private_class_method :git

    def self.parse_deployed_git_env(path, moduledir)
      env_repo = R10K::Git.provider::WorkingRepository.new(path, '')

      env_data = {
        :source => {
          :type => :git,
          :remote => env_repo.origin,
          :branch => nil, # TODO: store and extract from .r10k-deploy.json?
        },
        :version => env_repo.head,
        :resolved_at => nil, # TODO: Extract from .r10k-deploy.json? or current time?
      }

      # Add :modules declared in Puppetfile
      env_data.merge!(self.parse_puppetfile(File.join(path, "Puppetfile")))

      # Find the deployed version of each module.
      env_data[:modules].map! do |mod|
        mod_path = File.join(path, moduledir, mod[:name])
        mod.merge(parse_deployed_module(mod_path, mod[:type]))
      end

      return env_data
    end
    private_class_method :parse_deployed_git_env

    def self.parse_deployed_svn_env(path, moduledir)
      raise NotImplementedError
    end
    private_class_method :parse_deployed_svn_env

    def self.parse_deployed_module(path, type)
      mod = {}

      case type
      when :git
        git_head = File.join(path, '.git', 'HEAD')

        if File.exists?(git_head)
          mod[:resolved_version] = File.read(git_head).strip
        end
      when :svn
        # TODO
      when :forge
        # TODO: parse metadata.json/Modulefile?
      else
        raise RuntimeError, "unrecognized module type"
      end

      return mod
    end
    private_class_method :parse_deployed_module

    def self.resolve_git_module(mod, opts={})
      if !opts[:cachedir]
        raise RuntimeError.new("A value is required for the :cachedir option when resolving module from a git source.")
      end

      cachedir = cachedir_for_git_remote(mod[:source], opts[:cachedir])

      begin
        mod[:resolved_version] = git.rev_parse(mod[:version], git_dir: cachedir)
      rescue R10K::Git::GitError => e
        raise UnresolvableError.new("Unable to resolve '#{mod[:version]}' to a valid Git commit for module '#{mod[:name]}'.")
      end

      return mod
    end
    private_class_method :resolve_git_module

    def self.resolve_forge_module(mod, opts={})
      # If the module is "unpinned" and not already deployed, resolve as "latest" but preserve declared value of "unpinned".
      if mod[:version].to_sym == :unpinned
        if !mod[:deployed_version]
          resolve_to = :latest
        else
          resolve_to = mod[:deployed_version]
        end
      end

      # FIXME: if somehow they have a deployed but unpinned module whose version doesn't exist on Forge, this will
      # currently fail to resolve

      begin
        # TODO: Filter out deleted releases?
        candidates = PuppetForge::V3::Module.find(mod[:source]).releases
      rescue Faraday::ResourceNotFound => e
        raise UnresolvableError.new("Unable to resolve '#{mod[:name]}', '#{mod[:source]}' could not be found on the Puppet Forge.")
      end

      if resolve_to == :latest || mod[:version].to_sym == :latest
        # Find first non-prerelease version
        match_release = candidates.find { |release| SemanticPuppet::Version.parse(release.version).prerelease.nil? }
      else
        # Find first version matching range
        desired = SemanticPuppet::VersionRange.parse(resolve_to || mod[:version])
        match_release = candidates.find { |release| desired.include?(SemanticPuppet::Version.parse(release.version)) }
      end

      if match_release
        mod[:resolved_version] = match_release.version
      else
        raise UnresolvableError.new("Unable to resolve '#{mod[:name]}', no released version of '#{mod[:source]}' could be found on the Puppet Forge which matches the version or range: '#{mod[:version]}'")
      end

      return mod
    end
    private_class_method :resolve_forge_module

    def self.cachedir_for_git_remote(remote, cache_basedir)
      repo_path = remote.gsub(/[^@\w\.-]/, '-')

      return File.join(cache_basedir, repo_path)
    end
    private_class_method :cachedir_for_git_remote

    def self.cachedir_for_forge_module(module_slug, cache_basedir)
      return File.join(cache_basedir, module_slug)
    end
    private_class_method :cachedir_for_forge_module
  end
end
