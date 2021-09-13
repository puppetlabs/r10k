module R10K
  module Util

    # Utility mixin for classes that need to implement caches
    #
    # @abstract Classes using this mixin need to implement {#managed_directory} and
    #   {#desired_contents}
    module Cacheable

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
