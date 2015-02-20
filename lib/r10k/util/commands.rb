module R10K
  module Util
    module Commands
      module_function

      # Find the full path of a shell command.
      #
      # On POSIX platforms, the PATHEXT environment variable will be unset, so
      # the first command named 'cmd' will be returned.
      #
      # On Windows platforms, the PATHEXT environment variable will contain a
      # semicolon delimited list of executable file extensions, so the first
      # command with a matching path extension will be returned.
      #
      # @param cmd [String] The name of the command to search for
      # @return [String, nil] The path to the file if found, nil otherwise
      def which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |dir|
          exts.each do |ext|
            path = File.join(dir, "#{cmd}#{ext}")
            if File.executable?(path) && File.file?(path)
              return path
            end
          end
        end
        nil
      end
    end
  end
end
