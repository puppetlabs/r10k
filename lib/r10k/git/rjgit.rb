require 'r10k/logging'
require 'r10k/git/errors'

if R10K::Features.available?(:rjgit)
  require 'rjgit'
end

module R10K
  module Git
    module RJGit
      extend R10K::Logging

      module_function
      # -----------------------------------------------------------------------

      def blob_at(git_dir, commit_ish, path, opts = {})
        repo = ::RJGit::Repo.new(git_dir, is_bare: true)

        begin
          return repo.blob(path, commit_ish).data
        rescue Java::OrgEclipseJgitErrors::LargeObjectException,
               Java::OrgEclipseJgitErrors::MissingObjectException,
               Java::JavaIO::IOException => e
          raise R10K::Git::GitError.new(e.message)
        end
      end

      def branch_list(git_dir, opts = {})
        repo = ::RJGit::Repo.new(git_dir, is_bare: true)

        begin
          return repo.branches.collect { |branch| branch.gsub(/^refs\/heads\//, '') }
        rescue Java::OrgEclipseJgitApiErrors::GitAPIException => e
          raise R10K::Git::GitError.new(e.message)
        end
      end

      def clean(work_tree, opts = {})
        # TODO: Implement excludes.
        if opts[:excludes]
          raise NotImplementedError, "JGit's CleanCommand does not implement excludes."
        end

        # JGit doesn't appear to care about the --force option.

        repo = ::RJGit::Repo.new(work_tree, git_dir: opts[:git_dir])

        begin
          repo.clean
        rescue Java::OrgEclipseJgitApiErrors::GitAPIException,
               Java::OrgEclipseJgitErrors::NoWorkTreeException => e
          raise R10K::Git::GitError.new(e.message)
        end

        return true
      end

      def clone(remote, local, opts={})
        if local.nil?
          raise R10K::Git::GitError.new("CloneCommand requires that local argument be not nil.")
        end

        local_parent = File.expand_path('..', local)

        unless File.directory?(local_parent)
          raise R10K::Git::GitError.new("CloneCommand requires that local parent directory (#{local_parent}) already exist.")
        end

        clone_opts = {
          branch: :all,
          is_bare: opts[:bare],
        }
        clone_opts = clone_opts.merge(private_key_file: opts[:private_key]) if opts[:private_key]
        clone_opts = clone_opts.merge(username: opts[:username]) if opts[:username]

        begin
          ::RJGit::RubyGit.clone(remote, local, clone_opts)
        rescue Java::OrgEclipseJgitApiErrors::GitAPIException,
               Java::OrgEclipseJgitApiErrors::TransportException,
               Java::OrgEclipseJgitApiErrors::InvalidRemoteException => e
          raise R10K::Git::GitError.new(e.message)
        end

        return true
      end

      def fetch(git_dir, remote, opts={})
        repo = ::RJGit::Repo.new(git_dir, is_bare: true)

        fetch_opts = {
          refspecs: "+refs/*:refs/*",
        }
        fetch_opts = fetch_opts.merge(private_key_file: opts[:private_key]) if opts[:private_key]
        fetch_opts = fetch_opts.merge(username: opts[:username]) if opts[:username]

        begin
          repo.git.fetch(remote, fetch_opts)
        rescue Java::OrgEclipseJgitApiErrors::GitAPIException,
               Java::OrgEclipseJgitApiErrors::TransportException,
               Java::OrgEclipseJgitApiErrors::InvalidRemoteException => e
          raise R10K::Git::GitError.new(e.message)
        end

        return true
      end

      def reset(work_tree, commit_ish, opts = {})
        reset_mode = opts[:hard] ? "HARD" : "MIXED"

        if opts[:git_dir]
          repo_opts = {
            git_dir: File.expand_path(opts[:git_dir]),
          }
        else
          repo_opts = {}
        end

        repo = ::RJGit::Repo.new(work_tree, repo_opts)

        commit = resolve_in_repo(repo, commit_ish)

        if commit.nil?
          raise R10K::Git::GitError.new("Could not resolve '#{commit_ish}' to a commit in repo.")
        end

        begin
          repo.git.reset(commit, reset_mode)
        rescue Java::OrgEclipseJgitApiErrors::GitAPIException => e
          raise R10K::Git::GitError.new(e.message)
        end

        return true
      end

      def resolve_commit(git_dir, commit_ish, opts = {})
        repo = ::RJGit::Repo.new(git_dir, is_bare: true)

        commit = resolve_in_repo(repo, commit_ish)

        if commit.nil?
          raise R10K::Git::GitError.new("Could not resolve '#{commit_ish}' to a commit in repo.")
        end

        return commit.id
      end


      private
      # -----------------------------------------------------------------------

      def self.resolve_in_repo(repo, commit_ish)
        if commits = repo.commits(commit_ish)
          return commits.first
        else
          return nil
        end
      end
      private_class_method :resolve_in_repo
    end
  end
end
