require 'r10k/util/subprocess'
require 'r10k/util/setopts'

module R10K
  module SVN

    # Manage an SVN working copy.
    #
    # If SVN authentication is required, both username and password must be specified.
    #
    # @api private
    # @since 1.2.0
    class WorkingDir

      include R10K::Util::Setopts

      # @attribute [r] path
      #   @return [Pathname] The full path to the SVN working directory
      #   @api private
      attr_reader :path

      # @!attribute [r] username
      #   @return [String, nil] The SVN username, if provided
      #   @api private
      attr_reader :username

      # @!attribute [r] password
      #   @return [String, nil] The SVN password, if provided
      #   @api private
      attr_reader :password

      # @param path [Pathname]
      # @param opts [Hash]
      #
      # @option opts [String] :username
      # @option opts [String] :password
      def initialize(path, opts = {})
        @path = path

        setopts(opts, {:username => :self, :password => :self})

        if !!(@username) ^ !!(@password)
          raise ArgumentError, _("Both username and password must be specified")
        end
      end

      # Is the directory at this path actually an SVN repository?
      def is_svn?
        dot_svn = @path + '.svn'
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
        argv.concat(auth)

        svn(argv, :cwd => @path)
      end

      def checkout(url, revision = nil)
        argv = ['checkout', url]
        argv << '-r' << revision if revision
        argv << @path.basename.to_s
        argv.concat(auth)
        argv << '-q'

        svn(argv, :cwd => @path.parent)
      end

      private

      def info
        argv = %w[info]
        argv.concat(auth)
        svn(argv, :cwd => @path)
      end

      # Format authentication information for SVN command args, if applicable
      def auth
        auth = []
        if @username
          auth << "--username" << @username
          auth << "--password" << @password
        end
        auth
      end

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
        argv.unshift('svn', '--non-interactive')

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
