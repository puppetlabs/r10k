module R10K
  module Util

    # Utility mixin for classes that need to implement caches
    #
    # @abstract Classes using this mixin need to implement {#managed_directory} and
    #   {#desired_contents}
    module Cacheable

      # Provide a default cachedir location. This is consumed by R10K::Settings
      # for appropriate global default values.
      #
      # @return [String] Path to the default cache directory
      def self.default_cachedir(basename = 'cache')
        if R10K::Util::Platform.windows?
          File.join(ENV['LOCALAPPDATA'], 'r10k', basename)
        else
          File.join(ENV['HOME'] || '/root', '.r10k', basename)
        end
      end

      # Reformat a string into something that can be used as a directory
      #
      # @param string [String] An identifier to create a sanitized dirname for
      # @return [String] A sanitized dirname for the given string
      def sanitized_dirname(string)
        string.gsub(/(\w+:\/\/)(.*)(@)/, '\1').gsub(/[^@\w\.-]/, '-')
      end
    end
  end
end
