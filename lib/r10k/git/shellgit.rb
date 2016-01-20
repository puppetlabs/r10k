require 'r10k/logging'
require 'r10k/util/subprocess'

module R10K
  module Git
    module ShellGit
      require 'r10k/git/shellgit/bare_repository'
      require 'r10k/git/shellgit/working_repository'
      require 'r10k/git/shellgit/thin_repository'

      extend R10K::Logging

      module_function

      def reset(ref, opts = {})
        opts = { raise_on_fail: false }.merge(opts)

        cmd = ["reset", ref]

        if opts[:hard]
          cmd << "--hard"
        end

        result = git(cmd, opts)

        if result.success?
          return true
        else
          raise R10K::Git::GitError.new(result.stderr)
        end
      end

      def clean(opts = {})
        opts = { raise_on_fail: false }.merge(opts)

        cmd = ["clean"]

        if opts[:force]
          cmd << "--force"
        end

        if opts[:excludes]
          excludes = opts[:excludes].collect { |pattern| ["-e", pattern] }.flatten
          cmd.concat(excludes)
        end

        result = git(cmd, opts)

        if result.success?
          return true
        else
          raise R10K::Git::GitError.new(result.stderr)
        end
      end

      def rev_parse(rev, opts = {})
        opts = { raise_on_fail: false }.merge(opts)

        cmd = ["rev-parse", rev]

        result = git(cmd, opts)

        if result.success?
          return result.stdout.strip
        else
          raise R10K::Git::GitError.new(result.stderr)
        end
      end

      # Wrap git commands
      #
      # @param cmd [Array<String>] cmd The arguments for the git prompt
      # @param opts [Hash] opts
      #
      # @option opts [String] :path
      # @option opts [String] :git_dir
      # @option opts [String] :work_tree
      # @option opts [String] :raise_on_fail
      #
      # @raise [R10K::ExecutionFailure] If the executed command exited with a
      #   nonzero exit code.
      #
      # @return [String] The git command output
      def git(cmd, opts = {})
        raise_on_fail = opts.fetch(:raise_on_fail, true)

        argv = %w{git}

        if opts[:path]
          argv << "--git-dir"   << File.join(opts[:path], '.git')
          argv << "--work-tree" << opts[:path]
        else
          if opts[:git_dir]
            argv << "--git-dir" << opts[:git_dir]
          end
          if opts[:work_tree]
            argv << "--work-tree" << opts[:work_tree]
          end
        end

        argv.concat(cmd)

        subproc = R10K::Util::Subprocess.new(argv)
        subproc.raise_on_fail = raise_on_fail
        subproc.logger = self.logger

        result = subproc.execute

        result
      end
    end
  end
end
