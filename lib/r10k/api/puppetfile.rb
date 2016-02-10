require 'r10k/api/errors'
require 'r10k/api/util'

require 'r10k/logging'

module R10K
  module API
    # Namespace containing R10K::API methods that interact with and manipulate Puppetfiles.
    # These methods are extended into the base R10K::API namespace and should only be called from that context.
    #
    # @api private
    module Puppetfile
      extend R10K::Logging
      extend R10K::API::Util

      # Returns the contents of Puppetfile inside the given control repo source at the given version. Assumes source repo cache has already been updated if applicable.
      #
      # @param control_source [Hash]
      # @param commit_ish [String] Commit-ish reference to the version of the Puppetfile to extract. (For Git repos, accepts anything rev-parse would understand, e.g. "abc123", "production", "1.0.3", etc. For SVN repos, must be a branch name.)
      # @param puppetfile_path [String] Path, relative to the root of the control repo, at which the Puppetfile can be found.
      # @option opts [String] :cachedir Path where r10k should cache things.
      # @return [String] Return contents of Puppetfile at given commit, raises on failure.
      # @raise [RuntimeError]
      def get_puppetfile(control_source, commit_ish, puppetfile_path="", opts={})
        # Strip the leading slash to make a path relative to the root of the repo.
        puppetfile_path = File.join(puppetfile_path, "Puppetfile").sub(/^\/+/, '')

        case control_source[:type].to_sym
        when :git
          git_dir = cachedir_for_git_remote(control_source[:remote], opts[:cachedir])

          return git.blob_at(git_dir, commit_ish, puppetfile_path)
        when :svn
          if commit_ish == 'production'
            repo_path = "trunk/#{puppetfile_path}"
          else
            repo_path = "branches/#{commit_ish}/#{puppetfile_path}"
          end

          return R10K::SVN::Remote.new(control_source[:remote]).cat(repo_path)
        end
      end

      # Creates the modules portion of an abstract environment hashmap from the given Puppetfile.
      #
      # @param io_or_content [#read, String] A readable stream or String of Puppetfile contents.
      # @return [Array] An array representing the desired state of modules as specified in the passed in Puppetfile.
      # @raise RuntimeError
      def parse_puppetfile(io_or_content)
        builder = R10K::API::ModulesArrayBuilder.new
        parser = R10K::Puppetfile::DSL.new(builder)

        if io_or_content.respond_to?(:read)
          parser.instance_eval(io_or_content.read)
        else
          parser.instance_eval(io_or_content)
        end

        return builder.build
      end
    end
  end
end
