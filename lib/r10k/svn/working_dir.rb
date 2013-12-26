require 'r10k/logging'
require 'r10k/execution'

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
        info = svn "info"
        info.slice(/^Revision: (\d+)$/, 1)
      end

      def url
        info = svn "info"
        info.slice(/^URL: (.*)$/, 1)
      end

      def root
        info = svn "info"
        info.slice(/^Repository Root: (.*)$/, 1)
      end

      private

      def svn(args)
        cmd = "svn #{args.join(' ')}"
        log_event = "#{cmd.inspect}, repository: #{@full_path}"

        execute(cmd, :event => log_event, :cwd => @full_path.to_s)
      end
    end
  end
end
