module R10K
  # A low-level interface for triggering r10k operations.
  #
  # @example Parse a Puppetfile and deploy the environment it represents:
  #   # Given "ops_source" is an instance of R10K::Source
  #   puppetfile = R10K::API.get_puppetfile(ops_source.to_hash, "production")
  #   envmap = R10K::API.parse_puppetfile(puppetfile)
  #
  #   R10K::API.sources_for_environment(envmap).each do |source|
  #     R10K::API.update_cache(source)
  #   end
  #
  #   envmap = R10K::API.resolve_environment(envmap)
  #
  #   R10K::API.write_environment(envmap, ops_source.path_for("production"))
  #
  module API
    extend R10K::Logging

    extend self # TODO: split functions up into submodules and extend those instead?

    # Returns the contents of Puppetfile inside the given control repo source at the given version. Assumes source repo cache has already been updated.
    #
    # @param source [Hash] An hash representation of an R10K::Source style control repo as defined in r10k.yaml.
    # @param version [String] Commit-ish reference to the version of the Puppetfile to extract. (For Git repos, accepts anything rev-parse would understand, e.g. "abc123", "production", "1.0.3", etc.)
    # @param base_path [String] Path, relative to the root of the control repo, at which the Puppetfile can be found.
    # @return [String] Return contents of Puppetfile at given commit, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def get_puppetfile(source, version, base_path="")
    end

    # Creates an abstract environment hashmap from the given Puppetfile.
    #
    # @param io_or_path [#read, String] A readable stream of Puppetfile contents or a String path to a Puppetfile on disk.
    # @return [Hash] A hashmap representing the desired environment state as specified in the passed in Puppetfile.
    def parse_puppetfile(io_or_path)
    end

    # Creates a resolved environment hashmap representing the actual state of the Puppet environment found at the given path.
    #
    # @param path [String] Path on disk of the Puppet environment to be inspected.
    # @return [Hash] A hashmap representing the actual state of the environment found at path.
    def parse_deployed_env(path)
    end

    # Discover every Puppet environment under the given path and return a single hashmap containing the actual state
    # of every environment found.
    #
    # @param path [String] Path on disk to search for Puppet environments.
    # @return [Array<Hash>] An array of hashmaps, each representing the actual state of a single environment found in environmentdir.
    def parse_environmentdir(path)
    end

    # Return an array of all remote sources referenced by module declarations within the given environment hashmap.
    #
    # @param env_map [Hash] A hashmap representing a single environment's state.
    # @return [Array<Hash>] An array of hashes, each hash represents the type (:vcs or :forge) and location of a single remote module source.
    def sources_for_environment(env_map)
    end


    # Update local cache represented by the given source hashmap.
    #
    # @param source_map [Hash] A hashmap representing a single remote module source (as produced by {#sources_for_environment})
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def update_cache(source_map)
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
    def resolve_environment(env_map)
    end


    # Given a map representing a single module from an environment map, resolve any ambiguity in the module version.
    #
    # This function assumes that the relevant cache has already been updated.
    #
    # @param module_map [Hash] A hashmap representing a single module entry from an environment map.
    # @return [Hash] A copy of module_map with a new :resolved_version key/value pair added.
    def resolve_module(module_map)
    end


    # Given an environment map, write the base environment and all Puppetfile declared modules to disk at the given path.
    #
    # @param env_map [Hash] A fully-resolved (see {#resolve_environment}) hashmap representing a single environment's new state.
    # @param path [String] Path on disk into which the given environment should be deployed. The given path should already include the environment's name. (e.g. /puppet/environments/production not /puppet/environments) Path will be created if it does not already exist.
    # @param opts [Hash] Additional options as defined.
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def write_environment(env_map, path, opts={})
    end

    # Given an environment map, write the base environment only (not any Puppetfile declared modules) to disk at the given path.
    #
    # @param env_map [Hash] A fully-resolved (see {#resolve_environment}) hashmap representing a single environment's new state.
    # @param path [String] Path on disk into which the given environment should be deployed. The given path should already include the environment's name. (e.g. /puppet/environments/production not /puppet/environments) Path will be created if it does not already exist.
    # @param opts [Hash] Additional options as defined.
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def write_env_base(env_map, path, opts={})
    end

    # Write the given module, using the version/commit declared in the given environment map, to disk at the given path.
    #
    # @param module_name [String] Name of the module to be written to disk, should match the value of the "name" key in the supplied environment map.
    # @param env_map [Hash] A fully-resolved (see {#resolve_environment}) hashmap representing a single environment's new state.
    # @param path [String] Path on disk into which the given module should be deployed. The given path should already include the environment's name. (e.g. /puppet/environments/production not /puppet/environments) Path will be created if it does not already exist.
    # @param opts [Hash] Additional options as defined.
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError] Something bad happened!
    def write_module(module_name, env_map, path, opts={})
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

    private

  end
end
