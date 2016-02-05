require 'r10k/api/errors'
require 'r10k/api/util'

require 'r10k/environment/name'
require 'r10k/logging'

module R10K
  module API
    # Namespace containing R10K::API methods that interact primarily with one or more environments.
    # These methods are extended into the base R10K::API namespace and should only be called from that context.
    #
    # @api private
    module Environments
      extend R10K::Logging
      extend R10K::API::Util

      # Create an unresolved environment hashmap representing the desired state of a Puppet environment based on a source and branch.
      #
      # @param control_source [Hash] A hashmap representing a control repo source (like would be defined in r10k.yaml)
      # @param env_name [String] Environment name to build an envmap for.
      # @option opts [String] :cachedir Path where r10k should cache things.
      # @return [Hash] A hashmap representing the desired state of the environment matching the given branch in the given source.
      # @raise [NotImplementedError] Control repo source has a type that is not currently supported.
      # @raise [RuntimeError]
      def envmap_from_source(control_source, env_name, opts={})
        # TODO: enforce valid Puppet environment name here? verify prefix? maybe just use R10K::Environment::Name?
        branch_name = env_name

        if control_source[:prefix]
          if control_source[:prefix].is_a? String
            branch_name = env_name.gsub(/^#{Regexp.quote(control_source[:prefix])}_/, '')
          else
            branch_name = env_name.gsub(/^#{Regexp.quote(control_source[:name])}_/, '')
          end
        end

        case control_source[:type].to_sym
        when :git
          git_dir = cachedir_for_git_remote(control_source[:remote], opts[:cachedir])

          begin
            commit_sha = git.resolve_commit(git_dir, branch_name)
          rescue R10K::Git::GitError => e # FIXME: I don't think this is the right exception class anymore
            raise RuntimeError.new("Unable to resolve branch name '#{branch_name}' to a Git commit: #{e.message}")
          end

          # TODO: figure out how to pass through base_path option
          puppetfile = get_puppetfile(control_source, commit_sha)
        when :svn
          raise NotImplementedError
        else
          raise RuntimeError.new("Unrecognized control repo source type: #{source[:type]}")
        end

        return {
          environment: env_name,
          source: control_source,
          version: commit_sha,
          resolved_at: nil,
          modules: parse_puppetfile(puppetfile),
        }
      end

      # Return a list of sanitized environment names, including prefix, from the branches of the given source.
      #
      # @param source [Hash] A hashmap representing a control repo source (like would be defined in r10k.yaml)
      # @param opts [Hash] Additional options as defined.
      # @option opts [String] :cachedir Base path where caches are stored.
      # @return [Array<String>] An array of sanitized and prefixed (if appropriate) environment names.
      # @raise [NotImplementedError] Currently does not support SVN control repo sources.
      # @raise [RuntimeError]
      def get_environments_for_source(control_source, opts={})
        case control_source[:type].to_sym
        when :git
          git_dir = cachedir_for_git_remote(control_source[:remote], opts[:cachedir])
          branches = git.branch_list(git_dir)
        when :svn
          raise NotImplementedError
        else
          raise RuntimeError.new("Unrecognized control repo source type.")
        end

        env_name_opts = { source: control_source, prefix: control_source[:prefix], correct: true }

        environments = branches.collect do |branch|
          R10K::Environment::Name.new(branch, env_name_opts).dirname
        end

        return environments
      end

      # Creates a resolved environment hashmap representing the actual state of the Puppet environment found at the given path.
      #
      # @param path [String] Path on disk of the Puppet environment to be inspected.
      # @options opts [String] :moduledir The path, relative to the environment, where modules are deployed. (Default: "modules")
      # @return [Hash] A hashmap representing the actual state of the environment found at path.
      # @raise RuntimeError
      def parse_deployed_env(path, opts={})
        moduledir = opts[:moduledir] || default_moduledir

        env_name = path.split(File::SEPARATOR).last

        # TODO: set :deployed_version for all deployed modules
        # TODO: support multiple moduledirs? (include moduledirs in .r10k-deploy.json?)

        # FIXME: this doesn't work with GIT_WORK_TREE deploys now
        # maybe just read .r10k-deploy.json?

        env_data = case
                   when File.directory?(File.join(path, '.git')) then parse_deployed_git_env(path, opts)
                   when File.directory?(File.join(path, '.svn')) then parse_deployed_svn_env(path, opts)
                   else
                     # TODO: Real exception class
                     raise RuntimeError, "unrecognized deployed environment format"
                   end

        return { :environment => env_name }.merge(env_data)
      end

      # Discover every Puppet environment under the given path and return a single hashmap containing the actual state
      # of every environment found.
      #
      # @param path [String] Path on disk to search for Puppet environments.
      # @option opts [String] :moduledir The path, relative to the environment, where modules are deployed. (Default: "modules")
      # @return [Array<Hash>] An array of hashmaps, each representing the actual state of a single environment found in environmentdir.
      def parse_environmentdir(path, opts={})
        deployed_env_states = []

        if path
          deployed_envs = Dir.glob(File.join(path, '*')).select {|f| File.directory? f}
          deployed_envs.each do |env_dir|
            deployed_env_states << parse_deployed_env(env_dir, opts)
          end
        end

        return deployed_env_states
      end

      # Remove any deployed environments from the given path that do not exist in the given environment list.
      #
      # @param path [String] Path on disk to the base environmentdir from which to remove environments.
      # @param env_list [Array<String>] Array of environment names which should NOT be purged.
      # @return [true] Returns true on success, raises on failure.
      # @raise [RuntimeError]
      def purge_unmanaged_environments(path, env_list, opts={})
      end

      # Given an environment map, returns a new environment map with any ambiguous module versions (e.g. branch names, version ranges, etc.)
      # resolved to specific versions (or commit SHAs).
      #
      # If passed an already resolved environment, this function will have no effect.
      #
      # This function assumes that all relevant caches have already been updated.
      #
      # @param env_map [Hash] A hashmap representing a single environment's desired state.
      # @option opts [String] :cachedir Base path where caches are stored.
      # @option opts [Hash] :forge Additional options to control interaction with a Puppet Forge API implementation.
      # @option opts [Hash] :git Additional options to control interaction with remote Git repositories.
      # @return [Hash] A copy of env_map with :resolved_version key/value pairs added to each module and a :resolved_at timestamp added.
      # @raise [R10K::API::UnresolvableError] The env_map could not be fully resolved.
      def resolve_environment(env_map, opts={})
        # FIXME: This method needs to be more consistent about returning a completely new instance of the env_map in all cases.

        # Return already resolved envmaps unchanged.
        return env_map if env_map[:resolved_at]

        # Deep copy of modules list to iterate over.
        unresolved = env_map[:modules].map { |mod| mod.dup }

        # Capture any unresolvable modules so we can report them all at once.
        unresolvable = []

        unresolved.each do |mod|
          begin
            env_map = resolve_module(mod[:name], env_map, opts)
          rescue R10K::API::Errors::UnresolvableError => e
            unresolvable << mod.merge(:error => e)
          end
        end

        unless unresolvable.empty?
          raise R10K::API::Errors::UnresolvableError.new("The given environment map contains errors that prevent it from being fully resolved.", unresolvable)
        end

        env_map[:resolved_at] = Time.new

        return env_map
      end

      # Given an environment map, write the base environment and all Puppetfile declared modules to disk at the given path.
      #
      # @param env_map [Hash] A fully-resolved (see {#resolve_environment}) hashmap representing a single environment's new desired state.
      # @param path [String] Path on disk into which the given environment should be deployed. The given path should already include the environment's name. (e.g. /puppet/environments/production not /puppet/environments) Path will be created if it does not already exist.
      # @option opts [String] :cachedir Base path where caches are stored.
      # @option opts [Hash] :forge Additional options to control interaction with a Puppet Forge API implementation.
      # @option opts [Hash] :git Additional options to control interaction with remote Git repositories.
      # @option opts [String] :moduledir The path, relative to the environment, where modules are deployed. (Default: "modules")
      # @option opts [Boolean] :clean Remove untracked files after write.
      # @return [true] Returns true on success, raises on failure.
      # @raise [RuntimeError]
      def write_environment(env_map, path, opts={})
        moduledir = opts[:moduledir] || default_moduledir

        write_env_base(env_map, path, opts)

        env_map[:modules].each do |m|
          # TODO: use R10K::Environment::Name to calculate module portion of path?
          write_module(m[:name], env_map, File.join(path, moduledir, m[:name]), opts)
        end

        # Write resolved env-map to disk
        File.open(File.join(path, '.r10k-deploy.json'), 'w') do |fh|
          fh.write(JSON.pretty_generate(env_map))
        end

        return true
      end

      # Given an environment map, write the base environment only (not any Puppetfile declared modules) to disk at the given path.
      #
      # @param env_map [Hash] A fully-resolved (see {#resolve_environment}) hashmap representing a single environment's new state.
      # @param path [String] Path on disk into which the given environment should be deployed. The given path should already include the environment's name. (e.g. /puppet/environments/production not /puppet/environments) Path will be created if it does not already exist.
      # @option opts [String] :cachedir Base path where caches are stored.
      # @option opts [Hash] :git Additional options to control interaction with remote Git repositories.
      # @option opts [Boolean] :clean Remove untracked files in path after writing environment?
      # @return [true] Returns true on success, raises on failure.
      # @raise [RuntimeError]
      def write_env_base(env_map, path, opts={})
        if !File.directory?(path)
          FileUtils.mkdir_p(path)
        end

        case env_map[:source][:type].to_sym
        when :git
          git_dir = cachedir_for_git_remote(env_map[:source][:remote], opts[:cachedir])

          git.reset(path, env_map[:version], git_dir: git_dir, hard: true)

          if opts[:clean]
            git.clean(path, git_dir: git_dir, force: true)
          end
        else
          raise NotImplementedError
        end

        return true
      end

      # Private class methods.
      # -----------------------------------------------------------------------

      def self.parse_deployed_git_env(path, moduledir)
        # FIXME: this needs to use R10K::API::Git methods
        #
        env_repo = R10K::Git.provider::WorkingRepository.new(path, '')

        env_data = {
          source: {
            type: :git,
            remote: env_repo.origin,
            branch: nil, # TODO: store and extract from .r10k-deploy.json?
          },
          version: env_repo.head,
          resolved_at: nil, # TODO: Extract from .r10k-deploy.json? or current time?
          modules: parse_puppetfile(File.join(path, "Puppetfile"))
        }

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
    end
  end
end
