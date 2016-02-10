require 'r10k/api/environments'
require 'r10k/api/modules'
require 'r10k/api/puppetfile'
require 'r10k/api/caching'

require 'r10k/api/modules_array_builder'
require 'r10k/api/util'

require 'r10k/logging'
require 'r10k/git'
require 'r10k/git/errors'

require 'r10k/svn/remote'

require 'r10k/puppetfile'
require 'r10k/environment/name'

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
    extend R10K::API::Util

    # TODO: yardoc sections for control_source, module_source, env_map, possibly as wrapper classes around a Hash instance?

    module_function
    # -------------------------------------------------------------------------

    extend R10K::API::Environments
    extend R10K::API::Modules
    extend R10K::API::Puppetfile
    extend R10K::API::Caching

    # Given an environment name and a collection of control sources, deploy an environment and all of it's Puppetfile declared modules into the given basedir. Will automatically update caches as needed.
    #
    # @param env_name [String] Name of environment to deploy, including prefix if applicable.
    # @param basedir [String] Path on disk into which the given environment should be deployed. (E.g. "/etc/puppetlabs/code-staging/environments")
    # @param sources [Hash] A hash of control_sources as defined by users r10k.yaml config.
    # @option opts [String] :cachedir Base path where caches are stored.
    # @option opts [Hash] :forge Additional options to control interaction with a Puppet Forge API implementation.
    # @option opts [Hash] :git Additional options to control interaction with remote Git repositories.
    # @option opts [Boolean] :purge Whether or not to purge unmanaged modules in the given environment path after deploy. Default: false
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError]
    def deploy_environment(env_name, basedir, sources, opts={})
      source_environments = {}

      # Collect environments (branches) for each source
      sources.each do |name, src|
        update_git_cache(src[:remote], opts)

        # FIXME: Remove the need to merge the :type into there.
        source_environments[name] = get_environments_for_source(src.merge(type: :git), opts)
      end

      # find target environment/source in source_environments
      # FIXME: implement and define collision behavior
      source = { name: sources.keys.first, type: :git }.merge(sources.values.first)

      envmap = envmap_from_source(source, env_name, opts)

      return deploy_envmap(envmap, File.join(basedir, env_name), opts)
    end

    # Deploy an environment and all its modules, as represented by an env_map, into the given path, automatically updating module sources as needed.
    #
    # @param env_map [Hash] An abstract or resolved environment map.
    # @param path [String] Path on disk into which the given environment should be deployed. The given path should already include the environment's name. (e.g. /puppet/environments/production not /puppet/environments) Path will be created if it does not already exist.
    # @option opts [String] :cachedir Base path where caches are stored.
    # @option opts [Hash] :forge Additional options to control interaction with a Puppet Forge API implementation.
    # @option opts [Hash] :git Additional options to control interaction with remote Git repositories.
    # @option opts [Boolean] :purge Whether or not to purge unmanaged modules in the given environment path after deploy. Default: false
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError]
    def deploy_envmap(env_map, path, opts={})
      module_sources_for_environment(env_map).each do |mod_src|
        update_cache(mod_src, opts)
      end

      env_map = resolve_environment(env_map, opts)

      write_environment(env_map, path, opts)

      if opts[:purge]
        purge_unmanaged_modules(path, env_map)
      end

      return true
    end

    # Deploy a single module into a given environment path, updating module cache as needed.
    #
    # @param module_name [String] Name of the module to be deployed, should match the value of the "name" key in the supplied environment map.
    # @param env_map [Hash] A hashmap representing a single environment's desired state.
    # @param path [String] Path on disk to the environment into which the given module should be deployed. The given path should already include the environment's name. (e.g. /puppet/environments/production not /puppet/environments) Path will be created if it does not already exist.
    # @option opts [String] :cachedir Base path where caches are stored.
    # @option opts [Hash] :forge Additional options to control interaction with a Puppet Forge API implementation.
    # @option opts [Hash] :git Additional options to control interaction with remote Git repositories.
    # @return [true] Returns true on success, raises on failure.
    # @raise [RuntimeError]
    def deploy_module_into_env(module_name, env_map, path, opts={})
      update_cache(module_source_for_module(module_name, env_map), opts)

      env_map = resolve_module(module_name, env_map, opts)

      write_module(module_name, env_map, path, opts)

      return true
    end
  end
end
