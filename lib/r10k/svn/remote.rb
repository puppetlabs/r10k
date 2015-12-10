require 'r10k/util/subprocess'
require 'r10k/util/setopts'

module R10K
  module SVN
    # Inspect and interact with SVN remote repositories
    #
    # @api private
    # @since 1.3.0
    class Remote

      include R10K::Util::Setopts

      def initialize(baseurl, opts = {})
        @baseurl = baseurl
        setopts(opts, {:username => :self, :password => :self})
      end

      # @todo validate that the path to trunk exists in the remote
      def trunk
        "#{@baseurl}/trunk"
      end

      # @todo gracefully handle cases where no branches exist
      def branches
        argv = ['ls', "#{@baseurl}/branches"]
        argv.concat(auth)
        text = svn(argv)
        text.lines.map do |line|
          line.chomp!
          line.gsub!(%r[/$], '')
          line
        end
      end

      def cat(path, revision=nil)
        argv = ['cat']
        argv << "-r #{revision}" if revision
        argv << "#{@baseurl}/#{path}"

        argv.concat(auth)

        svn(argv)
      end

      private

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
