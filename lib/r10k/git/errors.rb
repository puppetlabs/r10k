require 'r10k/errors'

module R10K
  module Git

    class GitError < R10K::Error
      attr_reader :git_dir

      def initialize(mesg, options = {})
        super
        @git_dir = @options[:git_dir]
      end

      def message
        msg = super
        if @git_dir
          msg << " at #{@git_dir}"
        end
        msg
      end
    end


    class UnresolvableRefError < GitError

      attr_reader :ref

      def initialize(mesg, options = {})
        super
        @ref = @options[:ref]
      end
    end
  end
end
