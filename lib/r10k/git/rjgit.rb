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

      def reset(ver, opts = {})
        reset_mode = opts[:hard] ? "HARD" : "MIXED"

        repo = ::RJGit::Repo.new(opts[:work_tree], git_dir: opts[:git_dir])
        opts[:repo] = repo
        commit = resolve_version(ver, opts)

        if commit.nil?
          raise R10K::Git::GitError.new("Could not resolve '#{ver}' to a commit in repo.")
        end

        begin
          repo.git.reset(commit, reset_mode)
        rescue Java::OrgEclipseJgitApiErrors::GitAPIException => e
          raise R10K::Git::GitError.new(e.message)
        end

        return true
      end

      def clean(opts = {})
        # TODO: implement excludes:
        if opts[:excludes]
          raise NotImplementedError, "rjgit clean does not implement excludes, yet."
        end

        repo = ::RJGit::Repo.new(opts[:work_tree], git_dir: opts[:git_dir])

        begin
          repo.clean
        rescue Java::OrgEclipseJgitApiErrors::GitAPIException,
               Java::OrgEclipseJgitErrors::NoWorkTreeException => e
          raise R10K::Git::GitError.new(e.message)
        end

        return true
      end

      def rev_parse(ver, opts = {})
        commit = resolve_version(ver, opts)

        if commit.nil?
          raise R10K::Git::GitError.new("Could not resolve '#{ver}' to a commit in repo.")
        end

        return commit.id
      end

      private

      def self.resolve_version(ver, opts = {})
        repo = opts[:repo] || ::RJGit::Repo.new(opts[:git_dir], is_bare: true)

        if commits = repo.commits(ver)
          return commits.first
        else
          return nil
        end
      end
      private_class_method :resolve_version
    end
  end
end
