require 'r10k/errors'

module R10K
  module Git

    class GitError < R10K::Error; end

    class UnresolvableRefError < GitError

      attr_reader :ref
      attr_reader :git_dir

      def initialize(*args)
        super

        @hash    = @options[:ref]
        @git_dir = @options[:git_dir]
      end

      HASHLIKE = %r[[A-Fa-f0-9]]

      # Print a friendly error message if an object hash is given as the message
      def message
        if @mesg
          msg = @mesg
        else
          msg = "Could not locate hash"

          if @hash
            msg << " '#{@hash}'"
          end
        end

        if @git_dir
          msg << " at #{@git_dir}"
        end

        msg
      end
    end
  end
end
