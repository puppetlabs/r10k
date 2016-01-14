require 'r10k/logging'

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
        repo.git.reset(commit, reset_mode)
      end

      def clean(opts = {})
        # TODO: implement excludes:
        if opts[:excludes]
          raise NotImplementedError, "rjgit clean does not implement excludes, yet."
        end

        repo = ::RJGit::Repo.new(opts[:work_tree], git_dir: opts[:git_dir])
        repo.clean
      end

      def rev_parse(ver, opts = {})
        ref = resolve_version(ver, opts)
        ref.id
      end

      private

      def self.resolve_version(ver, opts = {})
        repo = opts[:repo] || ::RJGit::Repo.new(opts[:git_dir], is_bare: true)
        ref = repo.commits(ver).first
      end

      private_class_method :resolve_version
    end
  end
end
