require 'r10k/git'
require 'r10k/logging'

module R10K
  module API
    # Generic (not provider specific) high-level Git operations as required by the R10K::API public interface methods.
    module Git
      module_function
      # -----------------------------------------------------------------------

      # Extract the contents of the blob at the given path and commit from the given repo.
      #
      # @param git_dir [String] Path to GIT_DIR of the repo containing the target blob.
      # @param commit_ish [String] Git commit-ish reference to a commit containing target blob.
      # @param path [String] Path, relative to repo root, of the target blob.
      # @return [String] Raw contents of target blob.
      # @raise [R10K::Git::GitError] An error was encountered, see exception message.
      def blob_at(git_dir, commit_ish, path, opts={})
        git_opts = filter_opts(opts)

        provider.blob_at(git_dir, commit_ish, path, git_opts)
      end

      # Get a list of all available local branches in the given repo.
      #
      # @param git_dir [String] Path to GIT_DIR of the repo to list the branches of.
      # @return [Array<String>] An array of branch names.
      # @raise [R10K::Git::GitError] An error was encountered, see exception message.
      def branch_list(git_dir, opts={})
        git_opts = filter_opts(opts)

        provider.branch_list(git_dir, git_opts)
      end

      # Remove untracked files from a given working tree.
      #
      # @param work_tree [String] Path to the working tree to be cleaned.
      # @option opts [String] :git_dir Path to GIT_DIR containing the repo for given working tree (defaults to .git)
      # @option opts [Boolean] :force Whether to allow Git to remove files and directories, sometimes required by Git config.
      # @option opts [Array<String>] :excludes List of file patterns to exclude from the clean operation. Not supported by all providers.
      # @return [true] Working tree was successfully cleaned.
      # @raise [R10K::Git::GitError] An error was encountered, see exception message.
      def clean(work_tree, opts={})
        git_opts = filter_opts(opts, :git_dir, :force, :excludes)

        provider.clean(work_tree, git_opts)
      end

      # Create a local copy of the given remote repository at the path specified.
      #
      # @param local [String] Local path to clone the remote repository into.
      # @param remote [String] Git URI of the remote repo to be cloned.
      # @option opts [String] :private_key Path to private key file to use with SSH transport.
      # @option opts [String] :username Username to use for SSH transport when not specified in URI.
      # @option opts [Boolean] :bare Whether to make a "bare" repository (a repo with no working tree) at given path.
      # @return [true] Repo was successfully cloned to local path.
      # @raise [R10K::Git::GitError] An error was encountered, see exception message.
      def clone(local, remote, opts={})
        git_opts = filter_opts(opts, :private_key, :user, :bare)

        # TODO: swap arguments in provider to match
        provider.clone(remote, local, git_opts)
      end

      # Update the contents of an existing local repository with the contents of the given remote repository.
      #
      # @param git_dir [String] Path to GIT_DIR containing the local repo to be updated.
      # @param remote [String] Git URI of the remote repo to fetch from.
      # @option opts [String] :private_key Path to private key file to use for SSH transports.
      # @option opts [String] :username Username to use for SSH transports (when not specified in remote URI).
      # @return [true] Local repo was successfully updated.
      # @raise [R10K::Git::GitError] An error was encountered, see exception message.
      def fetch(git_dir, remote, opts={})
        git_opts = filter_opts(opts, :private_key, :username)

        provider.fetch(git_dir, remote, git_opts)
      end

      # Reset the contents of a working tree to the given commit-ish.
      #
      # @param work_tree [String] Path to the working tree to be reset.
      # @param commit_ish [String] Commit-ish reference to reset to.
      # @option opts [String] :git_dir Path to GIT_DIR for given working tree (defaults to .git)
      # @option opts [Boolean] :hard Whether to perform a "hard" reset, which resets both index and working tree.
      # @return [true] Working tree was successfully reset.
      # @raise [R10K::Git::GitError] An error was encountered, see exception message.
      def reset(work_tree, commit_ish, opts={})
        git_opts = filter_opts(opts, :git_dir, :hard)

        provider.reset(work_tree, commit_ish, git_opts)
      end

      # Resolve a commit-ish reference to the SHA1 hash of the specific commit it ultimately refers to.
      #
      # @param git_dir [String] Path to GIT_DIR containing the repo to resolve in.
      # @param commit_ish [String] Commit-ish reference to be resolved.
      # @return [String] SHA1 hash of a single commit.
      # @raise [R10K::Git::GitError] An error was encountered, see exception message.
      def resolve_commit(git_dir, commit_ish, opts={})
        git_opts = filter_opts(opts)

        provider.resolve_commit(git_dir, commit_ish, git_opts)
      end


      private
      # -----------------------------------------------------------------------

      def self.provider
        if R10K::Features.available?(:rjgit)
          R10K::Git.provider = :rjgit
        end

        return R10K::Git.provider
      end
      private_class_method :provider

      def self.filter_opts(opts, *allowed_keys)
        opts.select { |k,v| allowed_keys.include?(k) }
      end
      private_class_method :filter_opts
    end
  end
end
