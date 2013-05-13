module R10K
module Git
  class NonexistentHashError < StandardError
    # Raised when a hash was requested that can't be found in the repository

    attr_reader :hash
    attr_reader :git_dir

    def initialize(msg = nil, git_dir = nil)
      super(msg)

      @git_dir = git_dir
    end

    HASHLIKE = %r[[A-Fa-f0-9]]

    # Print a friendly error message if an object hash is given as the message
    def message
      msg = super
      if msg and msg.match(HASHLIKE)
        msg = "Could not locate hash #{msg.inspect} in repository"
      elsif msg.nil?
        msg = "Could not locate hash in repository"
      end

      if @git_dir
        msg << " at #{@git_dir}. (Does the remote repository need to be updated?)"
      end

      msg
    end
  end
end
end
