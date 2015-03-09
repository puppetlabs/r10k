module R10K
  module Util
    module SymbolizeKeys
      module_function

      # Convert all String keys to Symbol keys
      #
      # @param hash [Hash] The data structure to convert
      # @raise [TypeError] If a String key collides with an existing Symbol key
      # @return [void]
      def symbolize_keys!(hash)
        hash.keys.each do |key|
          next unless key.is_a? String
          if hash[key.to_sym]
            raise TypeError, "An existing interned key for #{key} exists, cannot overwrite"
          end
          hash[key.to_sym] = hash.delete(key)
        end
      end
    end
  end
end
