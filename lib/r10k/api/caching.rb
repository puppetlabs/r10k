require 'r10k/api/errors'
require 'r10k/api/util'

require 'r10k/logging'
require 'puppet_forge'

module R10K
  module API
    # Namespace containing R10K::API methods that support caching of control repo and module sources.
    # These methods are extended into the base R10K::API namespace and should only be called from that context.
    #
    # @api private
    module Caching
      extend R10K::Logging
      extend R10K::API::Util

      # Update local caches represented by the given by sources, a collection of control_source or module_source hashmaps.
      #
      # @param sources [Array<Hash>] An array of hashmaps each representing a single remote control or module source.
      # @option opts [String] :cachedir Root of where r10k is caching things.
      # @return [true] Returns true on success, raises on failure.
      # @raise [RuntimeError]
      def update_caches(sources, opts={})
        # FIXME: Make sure this works with a mix of both control and module sources.

        if sources.respond_to?(:each)
          sources.each do |src|
            update_cache(src, opts)
          end
        else
          raise RuntimeError.new("sources must be a collection of source hashes.")
        end

        return true
      end

      # Update local cache represented by the given control_source or module_source hashmap.
      #
      # @param source [Hash] A hashmap representing a single remote control or module source.
      # @option opts [String] :cachedir Root of where r10k is caching things.
      # @return [true] Returns true on success, raises on failure.
      # @raise [RuntimeError]
      # @raise [NotImplementedError]
      def update_cache(source, opts={})
        # FIXME: Make sure this works with both control and module sources.

        case source[:type].to_sym
        when :git
          update_git_cache(source[:source], opts)
        when :forge
          update_forge_cache(source[:source], opts)
        when :svn
          raise NotImplementedError
        else
          raise RuntimeError.new("Unrecognized module source type '#{source[:type]}'.")
        end
      end

      # Update local cache of the given remote git repository.
      #
      # @param remote [String] URI for the remote repository which should be cached or updated.
      # @option opts [String] :cachedir Base path where caches are stored.
      # @return [true] Returns true on success, raises on failure.
      # @raise [RuntimeError]
      def update_git_cache(remote, opts={})
        git_dir = cachedir_for_git_remote(remote, opts[:cachedir])
        git_opts = opts[:git] || {}

        if File.directory?(git_dir)
          git.fetch(git_dir, remote, git_opts)
        else
          git.clone(git_dir, remote, git_opts.merge({bare: true}))
        end
      end

      # Update local cache of the given module from the Puppet Forge.
      #
      # @param module_slug [String] Hyphen separated namespace and name of the module to be cached or updated. (E.g. "puppetlabs-apache")
      # @option opts [String] :cachedir Base path where caches are stored.
      # @option opts [Hash] :forge Additional options to control interaction with a Puppet Forge API implementation.
      # @return [true] Returns true on success, raises on failure.
      # @raise [RuntimeError]
      def update_forge_cache(module_slug, opts={})
        # This is currently a no-op.
        # This would have stored the response from a forge query for candidates for a release.
        # But if the forge module is already deployed, then we should already have the tarball.
        # The other case is that we need to get a new version, so the query will need to be fresh.
      end
    end
  end
end
