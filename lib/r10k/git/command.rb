module R10K
module Git
module Command
  # Define a trivial module to contain a wrapped version of the git command

  # Wrap git commands
  #
  # @param [String] command_line_args The arguments for the git prompt
  # @param [Hash] opts
  #
  # @option opts [String] :git_dir
  # @option opts [String] :work_tree
  # @option opts [String] :work_tree
  #
  # @return [String] The git command output
  def git(command_line_args, opts = {})
    args = %w{git}

    log_event = "git #{command_line_args}"
    log_event << ", args: #{opts.inspect}" unless opts.empty?


    if opts[:path]
      args << "--git-dir #{opts[:path]}/.git"
      args << "--work-tree #{opts[:path]}"
    else
      if opts[:git_dir]
        args << "--git-dir #{opts[:git_dir]}"
      end
      if opts[:work_tree]
        args << "--work-tree #{opts[:work_tree]}"
      end
    end

    args << command_line_args
    cmd = args.join(' ')

    execute(cmd, :event => log_event)
  end
end
end
end
