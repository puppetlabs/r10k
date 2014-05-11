require 'r10k/util/subprocess'

module R10K
  module SVN
    class WorkingDir

      # @param full_path [Pathname]
      def initialize(full_path)
        @full_path = full_path
      end

      def is_svn?
        dot_svn = @full_path + '.svn'
        dot_svn.exist?
      end

      def revision
        info.slice(/^Revision: (\d+)$/, 1)
      end

      def url
        info.slice(/^URL: (.*)$/, 1)
      end

      def root
        info.slice(/^Repository Root: (.*)$/, 1)
      end

      def update(revision = nil)
        argv = %w[update]
        argv << '-r' << revision if revision

        svn argv, :cwd => @full_path
      end

      def checkout(url, revision = nil)
        argv = ['checkout', url]
        argv << '-r' << revision if revision
        argv << @full_path.basename.to_s

        svn argv, :cwd => @full_path.parent
      end

      private

      def info
        svn ["info"], :cwd => @full_path
      end

      include R10K::Execution
      include R10K::Logging

      # Wrap SVN commands
      #
      # @param argv [Array<String>]
      # @param opts [Hash]
      #
      # @option opts [Pathname] :cwd The directory to run the command in
      #
      # @return [String] The stdout from the given command
      def svn(argv, opts = {})
        argv.unshift('svn')

        subproc = R10K::Util::Subprocess.new(argv)
        subproc.raise_on_fail = true
        subproc.logger = self.logger

        subproc.cwd = opts[:cwd]
        result = subproc.execute

        result.stdout
      end
    end
  end
end
